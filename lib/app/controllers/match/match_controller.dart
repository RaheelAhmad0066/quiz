import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/match/match_model.dart';
import '../../app_widgets/app_toast.dart';
import '../leaderboard_controller.dart';
import '../quiz_controller.dart';
import '../../services/gemini_service.dart';
import '../../services/send_notifcation_services.dart';

/// Match Controller - Handles match creation, joining, and gameplay
class MatchController extends GetxController {
  DatabaseReference? _databaseRef;
  
  DatabaseReference? get databaseRef {
    if (_databaseRef == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _databaseRef = FirebaseDatabase.instance.ref();
        }
      } catch (e) {
        print('Firebase Database not initialized: $e');
      }
    }
    return _databaseRef;
  }
  
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty && databaseRef != null;
    } catch (e) {
      return false;
    }
  }

  // Observable Lists
  final RxList<Map<String, dynamic>> availableUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> activeMatches = <Map<String, dynamic>>[].obs; // Active matches to join
  final RxList<Map<String, dynamic>> pendingInvitations = <Map<String, dynamic>>[].obs; // Invitations received
  final Rx<MatchModel?> currentMatch = Rx<MatchModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxInt questionTimer = 30.obs; // 30 seconds per question
  final RxInt currentQuestionIndex = 0.obs;
  final RxMap<String, int> playerAnswers = <String, int>{}.obs; // questionId -> selectedIndex
  final RxMap<String, Map<String, int>> allPlayersAnswers = <String, Map<String, int>>{}.obs; // userId -> {questionId -> selectedIndex}
  final RxBool isResultScreenShown = false.obs; // Prevent auto-navigation after result
  final RxSet<String> rejectedMatchIds = <String>{}.obs; // Track rejected match invitations
  
  // Navigation control
  DateTime? _lastNavigationTime;
  static const Duration _navigationCooldown = Duration(seconds: 30); // 30 seconds cooldown
  bool _userManuallyLeftLobby = false; // Track if user manually left lobby

  final searchController = TextEditingController();
  DatabaseReference? _matchListener;
  DatabaseReference? _invitationsListener;
  DatabaseReference? _notificationsListener; // Listen to notifications changes
  DatabaseReference? _answersListener;
  final GeminiService _geminiService = GeminiService();

  @override
  void onInit() {
    super.onInit();
    loadActiveMatches();
    loadPendingInvitations();
  }

  @override
  void onClose() {
    searchController.dispose();
    _matchListener?.onDisconnect();
    _invitationsListener?.onDisconnect();
    _notificationsListener?.onDisconnect();
    _answersListener?.onDisconnect();
    super.onClose();
  }
  
  /// Mark that user manually left lobby (prevents auto-navigation back)
  void markUserLeftLobby() {
    _userManuallyLeftLobby = true;
    // Reset after 5 minutes (user might want to come back)
    Future.delayed(Duration(minutes: 5), () {
      _userManuallyLeftLobby = false;
    });
  }
  
  /// Stop listening to match updates
  void stopListeningToMatch() {
    _matchListener?.onDisconnect();
    _answersListener?.onDisconnect();
    _matchListener = null;
    _answersListener = null;
    _userManuallyLeftLobby = false; // Reset flag
  }

  /// Load active matches that users can join
  Future<void> loadActiveMatches() async {
    if (!isFirebaseAvailable) return;

    try {
      isLoading.value = true;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Listen to matches in real-time
      _invitationsListener?.onDisconnect();
      _invitationsListener = databaseRef!.child('matches');
      
      _invitationsListener!.onValue.listen((event) async {
        if (event.snapshot.exists) {
          final matches = event.snapshot.value as Map<dynamic, dynamic>?;
          if (matches == null) {
            activeMatches.clear();
            return;
          }

          // Get user's rejected/accepted notifications to filter matches
          final notificationsSnapshot = await databaseRef!.child('notifications').child(currentUserId).get();
          final notifications = notificationsSnapshot.exists 
              ? Map<String, dynamic>.from(notificationsSnapshot.value as Map<dynamic, dynamic>)
              : <String, dynamic>{};

          final matchesList = <Map<String, dynamic>>[];
          
          for (var entry in matches.entries) {
            final matchId = entry.key.toString();
            final matchData = Map<String, dynamic>.from(entry.value as Map);
            final status = matchData['status']?.toString() ?? '';
            final isClosed = matchData['isClosed'] ?? false;
            final isLocked = matchData['isLocked'] ?? false;
            final players = (matchData['players'] as List<dynamic>?)
                    ?.map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p)))
                    .toList() ??
                [];
            
            // Check if user has rejected this match
            final notificationValue = notifications[matchId];
            final notificationData = notificationValue != null 
                ? Map<String, dynamic>.from(notificationValue as Map<dynamic, dynamic>)
                : null;
            final notificationStatus = notificationData?['status']?.toString() ?? 'pending';
            final isRejected = notificationStatus == 'rejected' || rejectedMatchIds.contains(matchId);
            
            // Only show matches that are:
            // - Not closed
            // - Waiting or starting status
            // - Not full (less than 4 players) OR just completed (to show winner)
            // - Not created by current user (or show if user is already in it)
            // - NOT rejected by current user (unless user is creator or already in match)
            final createdBy = matchData['createdBy']?.toString() ?? '';
            final isUserInMatch = players.any((p) => p.userId == currentUserId);
            final isUserCreator = createdBy == currentUserId;
            
            // Show match if:
            // 1. Not closed
            // 2. User is creator (to see their own matches) - ALWAYS show creator's matches (but not completed)
            // 3. OR (status is waiting AND not locked AND user not in match AND has space AND not rejected)
            // 4. OR (status is waiting AND user is in match) - show matches user joined
            // NOTE: Completed matches are NOT shown in match list (only in profile history)
            final shouldShow = !isClosed && status != 'completed' && (
              (isUserCreator && status == 'waiting') || // Creator's active matches only
              (status == 'waiting' && !isLocked && !isUserInMatch && players.length < (matchData['maxPlayers'] as int? ?? 4) && !isRejected) || // Available matches (not rejected)
              (status == 'waiting' && isUserInMatch) // Matches user joined
            );
            
            if (shouldShow) {
              // Get creator info - First try from match data (creatorStats), then fallback to leaderboard
              final creatorId = createdBy;
              Map<String, dynamic> creatorInfo = {
                'userName': 'Unknown',
                'userAvatar': null,
                'totalPoints': 0,
                'matchesWon': 0,
                'testsCompleted': 0,
                'rank': null,
              };
              
              // Try to get creator info from players first
              final creatorPlayer = players.firstWhereOrNull((p) => p.userId == creatorId);
              if (creatorPlayer != null) {
                creatorInfo = {
                  'userName': creatorPlayer.userName,
                  'userAvatar': creatorPlayer.userAvatar,
                  'totalPoints': 0,
                  'matchesWon': 0,
                  'testsCompleted': 0,
                  'rank': null,
                };
              }
              
              // First, try to get stats from match data (creatorStats) - saved when match was created
              final creatorStats = matchData['creatorStats'] as Map<dynamic, dynamic>?;
              if (creatorStats != null) {
                final stats = Map<String, dynamic>.from(creatorStats);
                creatorInfo['totalPoints'] = stats['totalPoints'] ?? 0;
                creatorInfo['matchesWon'] = stats['matchesWon'] ?? 0;
                creatorInfo['testsCompleted'] = stats['testsCompleted'] ?? 0;
                creatorInfo['rank'] = stats['rank'];
                print('✅ Using creator stats from match data: $stats');
              } else {
                // Fallback: Get creator stats from leaderboard (await to get data)
                try {
                  final leaderboardSnapshot = await databaseRef!.child('leaderboard').child('allTime').child(creatorId).get();
                  if (leaderboardSnapshot.exists) {
                    final leaderboardData = Map<String, dynamic>.from(leaderboardSnapshot.value as Map);
                    creatorInfo['totalPoints'] = leaderboardData['totalPoints'] ?? 0;
                    creatorInfo['matchesWon'] = leaderboardData['matchesWon'] ?? 0;
                    creatorInfo['testsCompleted'] = leaderboardData['testsCompleted'] ?? 0;
                  }
                } catch (e) {
                  print('Error fetching creator stats from leaderboard: $e');
                }
                
                // Get rank from leaderboard (await to get data)
                try {
                  final allSnapshot = await databaseRef!.child('leaderboard').child('allTime').get();
                  if (allSnapshot.exists) {
                    final allData = allSnapshot.value as Map<dynamic, dynamic>?;
                    if (allData != null) {
                      // Sort by totalPoints descending
                      final sorted = allData.entries.toList()
                        ..sort((a, b) {
                          final aData = Map<String, dynamic>.from(a.value as Map);
                          final bData = Map<String, dynamic>.from(b.value as Map);
                          final aPoints = aData['totalPoints'] as int? ?? 0;
                          final bPoints = bData['totalPoints'] as int? ?? 0;
                          return bPoints.compareTo(aPoints);
                        });
                      
                      // Find creator's rank
                      final rankIndex = sorted.indexWhere((entry) => entry.key.toString() == creatorId);
                      if (rankIndex >= 0) {
                        creatorInfo['rank'] = rankIndex + 1;
                      }
                    }
                  }
                } catch (e) {
                  print('Error fetching rank: $e');
                }
                
                // Also try to get from users node (await to get data)
                try {
                  final userSnapshot = await databaseRef!.child('users').child(creatorId).get();
                  if (userSnapshot.exists) {
                    final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                    if (creatorInfo['totalPoints'] == 0) {
                      creatorInfo['totalPoints'] = userData['totalPoints'] ?? 0;
                    }
                    if (creatorInfo['matchesWon'] == null || creatorInfo['matchesWon'] == 0) {
                      creatorInfo['matchesWon'] = userData['matchesWon'] ?? 0;
                    }
                    if (creatorInfo['testsCompleted'] == null || creatorInfo['testsCompleted'] == 0) {
                      creatorInfo['testsCompleted'] = userData['testsCompleted'] ?? 0;
                    }
                  }
                } catch (e) {
                  // Ignore error, use leaderboard data
                }
              }
              
              // Get winner info
              final scores = matchData['scores'] != null 
                  ? Map<String, int>.from(matchData['scores'] as Map)
                  : <String, int>{};
              String? winnerName;
              if (scores.isNotEmpty && status == 'completed') {
                final sortedScores = scores.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final winnerId = sortedScores.first.key;
                winnerName = players.firstWhereOrNull((p) => p.userId == winnerId)?.userName;
              }
              
              final maxPlayers = matchData['maxPlayers'] as int? ?? 4;
              
              matchesList.add({
                'matchId': matchId,
                'createdBy': creatorId,
                'creatorName': creatorInfo['userName'],
                'creatorAvatar': creatorInfo['userAvatar'],
                'creatorPoints': creatorInfo['totalPoints'] as int,
                'creatorWins': creatorInfo['matchesWon'] as int?,
                'creatorRank': creatorInfo['rank'] as int?,
                'creatorTestsCompleted': creatorInfo['testsCompleted'] as int?,
                'status': status,
                'isLocked': isLocked,
                'isClosed': isClosed,
                'playerCount': players.length,
                'maxPlayers': maxPlayers,
                'winnerName': winnerName,
                'scores': scores,
                'createdAt': matchData['createdAt'],
              });
            }
          }
          
          // Sort by creation time (newest first)
          matchesList.sort((a, b) {
            final aTime = a['createdAt'] as int? ?? 0;
            final bTime = b['createdAt'] as int? ?? 0;
            return bTime.compareTo(aTime);
          });
          
          activeMatches.value = matchesList;
        } else {
          activeMatches.clear();
        }
      });
    } catch (e) {
      print('Error loading active matches: $e');
      AppToast.showError('Failed to load matches');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load available users from leaderboard (exclude current user) - DEPRECATED
  Future<void> loadAvailableUsers() async {
    if (!isFirebaseAvailable) return;

    try {
      isLoading.value = true;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final snapshot = await databaseRef!.child('leaderboard').child('allTime').get();

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          // Get all users
          final allUsers = snapshotValue.entries
              .where((entry) => entry.key.toString() != currentUserId)
              .where((entry) => !entry.key.toString().startsWith('dummy_user_'))
              .map((entry) {
                final data = Map<String, dynamic>.from(entry.value);
                return {
                  'userId': entry.key.toString(),
                  'userName': data['userName'] ?? 'Unknown User',
                  'userEmail': data['userEmail'] ?? '',
                  'userAvatar': data['userAvatar'],
                  'totalPoints': data['totalPoints'] ?? 0,
                };
              })
              .toList();

          // Check which users are already in matches
          final activeMatchesSnapshot = await databaseRef!.child('matches').get();
          final activeUserIds = <String>{};
          
          if (activeMatchesSnapshot.exists) {
            final matches = activeMatchesSnapshot.value as Map<dynamic, dynamic>?;
            if (matches != null) {
              for (var matchEntry in matches.entries) {
                final matchData = matchEntry.value as Map<dynamic, dynamic>?;
                if (matchData != null) {
                  final status = matchData['status']?.toString() ?? '';
                  if (status == 'waiting' || status == 'starting' || status == 'inProgress') {
                    final players = matchData['players'] as List<dynamic>?;
                    if (players != null) {
                      for (var player in players) {
                        final playerData = player as Map<dynamic, dynamic>?;
                        if (playerData != null) {
                          activeUserIds.add(playerData['userId']?.toString() ?? '');
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // Add status to users
          availableUsers.value = allUsers.map((user) {
            final userId = user['userId'] as String;
            return {
              ...user,
              'inMatch': activeUserIds.contains(userId),
            };
          }).toList();

          // Sort by points
          availableUsers.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
        }
      }
    } catch (e) {
      print('Error loading available users: $e');
      AppToast.showError('Failed to load users');
    } finally {
      isLoading.value = false;
    }
  }

  /// Search users
  void searchUsers(String query) {
    if (query.isEmpty) {
      loadAvailableUsers();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    final queryLower = query.toLowerCase();

    availableUsers.value = availableUsers.where((user) {
      final name = (user['userName'] ?? '').toString().toLowerCase();
      final email = (user['userEmail'] ?? '').toString().toLowerCase();
      return name.contains(queryLower) || email.contains(queryLower);
    }).toList();
  }

  /// Load pending match invitations for current user
  Future<void> loadPendingInvitations() async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Listen to both matches AND notifications to get real-time updates
      _invitationsListener?.onDisconnect();
      _notificationsListener?.onDisconnect();
      
      _invitationsListener = databaseRef!.child('matches');
      _notificationsListener = databaseRef!.child('notifications').child(currentUserId);
      
      // Listen to matches changes
      _invitationsListener!.onValue.listen((event) async {
        await _updatePendingInvitations(currentUserId);
      });
      
      // Listen to notifications changes (when user accepts/rejects)
      _notificationsListener!.onValue.listen((event) async {
        await _updatePendingInvitations(currentUserId);
      });
      
      // Initial load
      await _updatePendingInvitations(currentUserId);
    } catch (e) {
      print('Error loading pending invitations: $e');
    }
  }
  
  /// Update pending invitations list based on current matches and notification status
  Future<void> _updatePendingInvitations(String currentUserId) async {
    try {
      // Get all matches
      final matchesSnapshot = await databaseRef!.child('matches').get();
      if (!matchesSnapshot.exists) {
        pendingInvitations.clear();
        return;
      }

      final matches = matchesSnapshot.value as Map<dynamic, dynamic>?;
      if (matches == null) {
        pendingInvitations.clear();
        return;
      }

      // Get all notifications for current user from Firebase (fresh data)
      final notificationsSnapshot = await databaseRef!.child('notifications').child(currentUserId).get();
      final notifications = notificationsSnapshot.exists 
          ? Map<String, dynamic>.from(notificationsSnapshot.value as Map<dynamic, dynamic>)
          : <String, dynamic>{};

      final invitations = <Map<String, dynamic>>[];
      
      for (var entry in matches.entries) {
        final matchId = entry.key.toString();
        final matchData = Map<String, dynamic>.from(entry.value as Map);
        final status = matchData['status']?.toString() ?? '';
        final players = (matchData['players'] as List<dynamic>?)
                ?.map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p)))
                .toList() ??
            [];
        
        // Check if this is an invitation for current user
        final isInvited = matchData['createdBy']?.toString() != currentUserId;
        final isNotJoined = !players.any((p) => p.userId == currentUserId);
        final isWaiting = status == 'waiting';
        final isNotClosed = !(matchData['isClosed'] ?? false);
        
        // Check notification status from Firebase (always get fresh data)
        final notificationValue = notifications[matchId];
        final notificationData = notificationValue != null 
            ? Map<String, dynamic>.from(notificationValue as Map<dynamic, dynamic>)
            : null;
        final notificationStatus = notificationData?['status']?.toString() ?? 'pending';
        
        // Also check local rejected list
        final isRejected = notificationStatus == 'rejected' || rejectedMatchIds.contains(matchId);
        final isAccepted = notificationStatus == 'accepted';
        
        // Show invitation if: invited, not joined, waiting, not rejected, not accepted, and not closed
        if (isInvited && isNotJoined && isWaiting && !isRejected && !isAccepted && isNotClosed) {
          // Get inviter info
          final inviterId = matchData['createdBy']?.toString() ?? '';
          final inviter = players.firstWhereOrNull((p) => p.userId == inviterId);
          
          // Check if notification is read
          final isRead = notificationData?['isRead'] ?? false;
          
          invitations.add({
            'matchId': matchId,
            'inviterId': inviterId,
            'inviterName': inviter?.userName ?? 'Someone',
            'inviterAvatar': inviter?.userAvatar,
            'createdAt': matchData['createdAt'],
            'isRead': isRead,
          });
        }
      }
      
      // Update the list (this will trigger UI update)
      pendingInvitations.value = invitations;
      
      if (kDebugMode) {
        print('📋 Updated pending invitations: ${invitations.length} invitations');
      }
    } catch (e) {
      print('❌ Error updating pending invitations: $e');
    }
  }

  /// Create a new match (without opponent - for public matches)
  Future<String?> createPublicMatch({
    String? categoryId,
    String? topicId,
    int maxPlayers = 4, // Default to 4, can be 2 or 4
  }) async {
    if (!isFirebaseAvailable) {
      AppToast.showError('Firebase not available');
      return null;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppToast.showError('Please login first');
        return null;
      }

      // Generate questions using Gemini AI (loading shown in UI)
      // Get topic name for Gemini
      String topicName = 'General Knowledge';
      try {
        if (topicId != null) {
          if (Get.isRegistered<QuizController>()) {
            final quizController = Get.find<QuizController>();
            await quizController.loadTopicsByCategory(categoryId ?? '');
            final topic = quizController.topics.firstWhereOrNull((t) => t.id == topicId);
            topicName = topic?.name ?? 'General Knowledge';
          }
        } else if (categoryId != null) {
          if (Get.isRegistered<QuizController>()) {
            final quizController = Get.find<QuizController>();
            await quizController.loadCategories();
            final category = quizController.categories.firstWhereOrNull((c) => c.id == categoryId);
            topicName = category?.name ?? 'General Knowledge';
          }
        }
      } catch (e) {
        print('⚠️ Error loading topic/category name: $e');
        // Continue with default topic name
      }

      // Generate 10 random MCQs using Gemini
      final questions = await _geminiService.generateMCQs(
        topic: topicName,
        count: 10,
        category: categoryId,
      );

      if (questions.isEmpty) {
        AppToast.showError('Failed to generate questions. Please check your internet connection.');
        return null;
      }
      
      // If we got less than 10, still proceed (fallback questions will be used)
      if (questions.length < 10) {
        print('⚠️ Only got ${questions.length} questions, proceeding with available questions');
      }

      // Create match with only creator
      final creator = MatchPlayer(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'User',
        userAvatar: currentUser.photoURL,
        userEmail: currentUser.email ?? '',
        isReady: false,
        joinedAt: DateTime.now(),
      );

      // Convert questions to match questions
      final matchQuestions = questions.map((q) {
        return MatchQuestion(
          questionId: q.id,
          question: q.question,
          options: q.options,
          correctAnswerIndex: q.correctAnswerIndex,
          explanation: q.explanation,
        );
      }).toList();

      // Create match with only creator
      final match = MatchModel(
        matchId: '',
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        status: MatchStatus.waiting,
        players: [creator],
        questions: matchQuestions,
        categoryId: categoryId,
        topicId: topicId,
        maxPlayers: maxPlayers, // 2 or 4 players
      );

      // Get creator stats from leaderboard/users to save with match
      int creatorPoints = 0;
      int creatorWins = 0;
      int creatorTestsCompleted = 0;
      int? creatorRank;
      
      try {
        // Get from leaderboard
        final leaderboardSnapshot = await databaseRef!.child('leaderboard').child('allTime').child(currentUser.uid).get();
        if (leaderboardSnapshot.exists) {
          final leaderboardData = Map<String, dynamic>.from(leaderboardSnapshot.value as Map);
          creatorPoints = leaderboardData['totalPoints'] ?? 0;
          creatorWins = leaderboardData['matchesWon'] ?? 0;
          creatorTestsCompleted = leaderboardData['testsCompleted'] ?? 0;
        }
        
        // Get rank
        final allSnapshot = await databaseRef!.child('leaderboard').child('allTime').get();
        if (allSnapshot.exists) {
          final allData = allSnapshot.value as Map<dynamic, dynamic>?;
          if (allData != null) {
            final sorted = allData.entries.toList()
              ..sort((a, b) {
                final aData = Map<String, dynamic>.from(a.value as Map);
                final bData = Map<String, dynamic>.from(b.value as Map);
                final aPoints = aData['totalPoints'] as int? ?? 0;
                final bPoints = bData['totalPoints'] as int? ?? 0;
                return bPoints.compareTo(aPoints);
              });
            final rankIndex = sorted.indexWhere((entry) => entry.key.toString() == currentUser.uid);
            if (rankIndex >= 0) {
              creatorRank = rankIndex + 1;
            }
          }
        }
        
        // Fallback to users node if leaderboard doesn't have data
        if (creatorPoints == 0) {
          final userSnapshot = await databaseRef!.child('users').child(currentUser.uid).get();
          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            creatorPoints = userData['totalPoints'] ?? 0;
            creatorWins = userData['matchesWon'] ?? 0;
            creatorTestsCompleted = userData['testsCompleted'] ?? 0;
          }
        }
      } catch (e) {
        print('⚠️ Error fetching creator stats: $e');
      }

      // Save to Firebase
      final matchRef = databaseRef!.child('matches').push();
      final matchId = matchRef.key!;

      // Ensure createdBy is explicitly set and include creator stats
      final matchData = {
        ...match.toJson(),
        'matchId': matchId,
        'createdBy': currentUser.uid, // Explicitly set to ensure it's saved
        'creatorStats': {
          'totalPoints': creatorPoints,
          'matchesWon': creatorWins,
          'testsCompleted': creatorTestsCompleted,
          'rank': creatorRank,
        },
      };
      
      print('✅ Creating public match with createdBy: ${currentUser.uid}');
      print('✅ Creator stats: Points=$creatorPoints, Wins=$creatorWins, Tests=$creatorTestsCompleted, Rank=$creatorRank');
      await matchRef.set(matchData);

      // Send notifications to all available users
      await _sendPublicMatchNotifications(matchId, currentUser.displayName ?? 'User');

      // Listen to match updates
      listenToMatch(matchId);
      
      // Refresh active matches list to show the new match
      await loadActiveMatches();

      print('✅ Match created successfully: $matchId');
      return matchId;
    } catch (e) {
      print('❌ Error creating match: $e');
      print('   Stack trace: ${StackTrace.current}');
      AppToast.showError('Failed to create match: ${e.toString()}');
      return null;
    }
  }

  /// Create a new match (with opponent - invitation based)
  Future<String?> createMatch({
    required String opponentUserId,
    String? categoryId,
    String? topicId,
  }) async {
    if (!isFirebaseAvailable) {
      AppToast.showError('Firebase not available');
      return null;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppToast.showError('Please login first');
        return null;
      }

      // Generate questions using Gemini AI
      AppToast.showInfo('Generating questions...');
      
      // Get topic name for Gemini
      String topicName = 'General Knowledge';
      if (topicId != null) {
        final quizController = Get.find<QuizController>();
        await quizController.loadTopicsByCategory(categoryId ?? '');
        final topic = quizController.topics.firstWhereOrNull((t) => t.id == topicId);
        topicName = topic?.name ?? 'General Knowledge';
      } else if (categoryId != null) {
        final quizController = Get.find<QuizController>();
        await quizController.loadCategories();
        final category = quizController.categories.firstWhereOrNull((c) => c.id == categoryId);
        topicName = category?.name ?? 'General Knowledge';
      }

      // Generate 10 random MCQs using Gemini
      final questions = await _geminiService.generateMCQs(
        topic: topicName,
        count: 10,
        category: categoryId,
      );

      if (questions.isEmpty) {
        AppToast.showError('Failed to generate questions. Please check your internet connection.');
        return null;
      }
      
      // If we got less than 10, still proceed (fallback questions will be used)
      if (questions.length < 10) {
        print('⚠️ Only got ${questions.length} questions, proceeding with available questions');
      }

      // Create match with only creator (opponent will join after accepting invitation)
      final creator = MatchPlayer(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'User',
        userAvatar: currentUser.photoURL,
        userEmail: currentUser.email ?? '',
        isReady: false,
        joinedAt: DateTime.now(),
      );

      // Convert questions to match questions
      final matchQuestions = questions.map((q) {
        return MatchQuestion(
          questionId: q.id,
          question: q.question,
          options: q.options,
          correctAnswerIndex: q.correctAnswerIndex,
          explanation: q.explanation,
        );
      }).toList();

      // Create match with only creator (opponent joins after accepting)
      final match = MatchModel(
        matchId: '',
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        status: MatchStatus.waiting,
        players: [creator], // Only creator initially
        questions: matchQuestions,
        categoryId: categoryId,
        topicId: topicId,
      );

      // Get creator stats from leaderboard/users to save with match
      int creatorPoints = 0;
      int creatorWins = 0;
      int creatorTestsCompleted = 0;
      int? creatorRank;
      
      try {
        // Get from leaderboard
        final leaderboardSnapshot = await databaseRef!.child('leaderboard').child('allTime').child(currentUser.uid).get();
        if (leaderboardSnapshot.exists) {
          final leaderboardData = Map<String, dynamic>.from(leaderboardSnapshot.value as Map);
          creatorPoints = leaderboardData['totalPoints'] ?? 0;
          creatorWins = leaderboardData['matchesWon'] ?? 0;
          creatorTestsCompleted = leaderboardData['testsCompleted'] ?? 0;
        }
        
        // Get rank
        final allSnapshot = await databaseRef!.child('leaderboard').child('allTime').get();
        if (allSnapshot.exists) {
          final allData = allSnapshot.value as Map<dynamic, dynamic>?;
          if (allData != null) {
            final sorted = allData.entries.toList()
              ..sort((a, b) {
                final aData = Map<String, dynamic>.from(a.value as Map);
                final bData = Map<String, dynamic>.from(b.value as Map);
                final aPoints = aData['totalPoints'] as int? ?? 0;
                final bPoints = bData['totalPoints'] as int? ?? 0;
                return bPoints.compareTo(aPoints);
              });
            final rankIndex = sorted.indexWhere((entry) => entry.key.toString() == currentUser.uid);
            if (rankIndex >= 0) {
              creatorRank = rankIndex + 1;
            }
          }
        }
        
        // Fallback to users node if leaderboard doesn't have data
        if (creatorPoints == 0) {
          final userSnapshot = await databaseRef!.child('users').child(currentUser.uid).get();
          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            creatorPoints = userData['totalPoints'] ?? 0;
            creatorWins = userData['matchesWon'] ?? 0;
            creatorTestsCompleted = userData['testsCompleted'] ?? 0;
          }
        }
      } catch (e) {
        print('⚠️ Error fetching creator stats: $e');
      }

      // Save to Firebase
      final matchRef = databaseRef!.child('matches').push();
      final matchId = matchRef.key!;

      // Ensure createdBy is explicitly set and include creator stats
      final matchData = {
        ...match.toJson(),
        'matchId': matchId,
        'createdBy': currentUser.uid, // Explicitly set to ensure it's saved
        'creatorStats': {
          'totalPoints': creatorPoints,
          'matchesWon': creatorWins,
          'testsCompleted': creatorTestsCompleted,
          'rank': creatorRank,
        },
      };
      
      print('✅ Creating match with createdBy: ${currentUser.uid}');
      print('✅ Creator stats: Points=$creatorPoints, Wins=$creatorWins, Tests=$creatorTestsCompleted, Rank=$creatorRank');
      await matchRef.set(matchData);

      // Send notification to opponent first
      await _sendMatchInvitationNotification(opponentUserId, matchId, currentUser.displayName ?? 'User');

      // Listen to match updates (will auto-navigate when opponent accepts)
      listenToMatch(matchId);

      AppToast.showSuccess('Invitation sent! Waiting for response...');
      return matchId;
    } catch (e) {
      print('Error creating match: $e');
      AppToast.showError('Failed to create match');
      return null;
    }
  }

  /// Join a match
  Future<void> joinMatch(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppToast.showError('Please login first');
        return;
      }

      final matchRef = databaseRef!.child('matches').child(matchId);
      final snapshot = await matchRef.get();

      if (!snapshot.exists) {
        AppToast.showError('Match not found');
        return;
      }

      final matchData = Map<String, dynamic>.from(snapshot.value as Map);
      final players = (matchData['players'] as List<dynamic>?)
              ?.map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          [];

      // Check if already in match
      if (players.any((p) => p.userId == currentUser.uid)) {
        // Reset manual leave flag since user is joining again
        _userManuallyLeftLobby = false;
        AppToast.showInfo('You are already in this match');
        listenToMatch(matchId);
        return;
      }

      // Get max players from match data
      final maxPlayers = matchData['maxPlayers'] as int? ?? 4;
      
      // Check if match is full
      if (players.length >= maxPlayers) {
        AppToast.showError('Match is full');
        return;
      }

      // Reset manual leave flag since user is joining
      _userManuallyLeftLobby = false;

      // Add player
      final newPlayer = MatchPlayer(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'User',
        userAvatar: currentUser.photoURL,
        userEmail: currentUser.email ?? '',
        isReady: false,
        joinedAt: DateTime.now(),
      );

      players.add(newPlayer);
      
      // Lock match if max players joined
      final shouldLock = players.length >= maxPlayers;

      await matchRef.update({
        'players': players.map((p) => p.toJson()).toList(),
        'isLocked': shouldLock,
      });

      // Listen to match updates
      listenToMatch(matchId);

      AppToast.showSuccess('Joined match!');
    } catch (e) {
      print('Error joining match: $e');
      AppToast.showError('Failed to join match');
    }
  }

  /// Listen to match updates
  void listenToMatch(String matchId) {
    _matchListener?.onDisconnect();
    
    _matchListener = databaseRef!.child('matches').child(matchId);
    _matchListener!.onValue.listen((event) {
      if (event.snapshot.exists) {
        final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final match = MatchModel.fromJson(matchData, matchId);
        currentMatch.value = match;
        
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isPlayerInMatch = match.players.any((p) => p.userId == currentUserId);
        
        // Don't auto-navigate if result screen is already shown (prevents restart bug)
        if (isResultScreenShown.value) return;
        
        // Check navigation cooldown (30 seconds)
        final now = DateTime.now();
        if (_lastNavigationTime != null) {
          final timeSinceLastNav = now.difference(_lastNavigationTime!);
          if (timeSinceLastNav < _navigationCooldown) {
            // Still in cooldown, don't navigate
            return;
          }
        }
        
        // Get current route
        final currentRoute = Get.currentRoute;
        
        // Auto-navigate based on status and player presence
        if (isPlayerInMatch) {
          if (match.status == MatchStatus.inProgress || match.status == MatchStatus.starting) {
            // Only navigate if not already on play screen
            if (currentRoute != '/match-play') {
              _lastNavigationTime = now;
              currentQuestionIndex.value = match.currentQuestionIndex;
              Get.offNamed('/match-play', arguments: {'matchId': matchId});
            }
          } else if (match.status == MatchStatus.waiting && match.players.length >= 2) {
            // Only navigate if not already on lobby screen AND user didn't manually leave
            if (currentRoute != '/match-lobby' && !_userManuallyLeftLobby) {
              _lastNavigationTime = now;
              Get.offNamed('/match-lobby', arguments: {'matchId': matchId});
            }
          } else if (match.status == MatchStatus.completed) {
            // Don't auto-navigate to result screen - let user stay on result screen
            // Navigation is handled by match_play_screen when match ends
            // This prevents auto-navigation that user doesn't want
          }
        }
      }
    });
    
    // Listen to all players' answers in real-time
    _listenToAllPlayersAnswers(matchId);
  }
  
  /// Listen to all players' answers for current question
  void _listenToAllPlayersAnswers(String matchId) {
    _answersListener?.onDisconnect();
    
    _answersListener = databaseRef!.child('matches').child(matchId).child('answers');
    _answersListener!.onValue.listen((event) {
      if (event.snapshot.exists) {
        final answers = event.snapshot.value as Map<dynamic, dynamic>;
        final allAnswers = <String, Map<String, int>>{};
        
        for (var playerEntry in answers.entries) {
          final playerId = playerEntry.key.toString();
          final playerAnswers = playerEntry.value as Map<dynamic, dynamic>;
          final questionAnswers = <String, int>{};
          
          for (var questionEntry in playerAnswers.entries) {
            final questionId = questionEntry.key.toString();
            final answerData = questionEntry.value as Map<dynamic, dynamic>;
            final selectedIndex = answerData['selectedIndex'] as int? ?? -1;
            questionAnswers[questionId] = selectedIndex;
          }
          
          allAnswers[playerId] = questionAnswers;
        }
        
        allPlayersAnswers.value = allAnswers;
      }
    });
  }

  /// Start match (when 2 or 4 players are ready based on maxPlayers)
  Future<void> startMatch(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final matchRef = databaseRef!.child('matches').child(matchId);
      await matchRef.update({
        'status': MatchStatus.starting.toString(),
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Wait 3 seconds then start
      await Future.delayed(Duration(seconds: 3));

      // Set question start time for timer synchronization
      await matchRef.update({
        'status': MatchStatus.inProgress.toString(),
        'currentQuestionIndex': 0,
        'currentQuestionStartTime': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error starting match: $e');
      AppToast.showError('Failed to start match');
    }
  }

  /// Submit answer for current question
  Future<void> submitAnswer(String matchId, int questionIndex, int selectedIndex) async {
    if (!isFirebaseAvailable) {
      print('⚠️ Firebase not available, cannot submit answer');
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ User not logged in, cannot submit answer');
        return;
      }

      final match = currentMatch.value;
      if (match == null) {
        print('⚠️ Match is null, cannot submit answer');
        return;
      }

      if (questionIndex < 0 || questionIndex >= match.questions.length) {
        print('⚠️ Invalid question index: $questionIndex (total: ${match.questions.length})');
        return;
      }

      final questionId = match.questions[questionIndex].questionId;
      final question = match.questions[questionIndex];
      playerAnswers[questionId] = selectedIndex;

      print('💾 Submitting answer: User=${currentUser.uid}, Question=$questionId, Answer=$selectedIndex');

      // Update match with answer
      final matchRef = databaseRef!.child('matches').child(matchId);
      final answersRef = matchRef.child('answers').child(currentUser.uid).child(questionId);
      
      await answersRef.set({
        'selectedIndex': selectedIndex,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Answer submitted successfully to Firebase');
      
      // Update score in real-time in matchScores collection
      await _updatePlayerScoreRealTime(matchId, currentUser.uid, question, selectedIndex);
    } catch (e) {
      print('❌ Error submitting answer: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Update player score in real-time when answer is submitted
  Future<void> _updatePlayerScoreRealTime(
    String matchId,
    String playerId,
    MatchQuestion question,
    int selectedIndex,
  ) async {
    if (!isFirebaseAvailable) return;
    
    try {
      final scoresRef = databaseRef!.child('matchScores').child(matchId).child('scores');
      
      // Get current score for this player
      final currentScoreSnapshot = await scoresRef.child(playerId).get();
      int currentScore = 0;
      
      if (currentScoreSnapshot.exists) {
        final scoreValue = currentScoreSnapshot.value;
        if (scoreValue is int) {
          currentScore = scoreValue;
        } else if (scoreValue is String) {
          currentScore = int.tryParse(scoreValue) ?? 0;
        }
      }
      
      // Check if answer is correct
      final isCorrect = selectedIndex >= 0 && selectedIndex == question.correctAnswerIndex;
      
      if (isCorrect) {
        // Increment score
        final newScore = currentScore + 1;
        await scoresRef.child(playerId).set(newScore);
        print('✅ Real-time score update: $playerId = $newScore (correct answer)');
      } else {
        // Ensure score exists (even if 0)
        if (!currentScoreSnapshot.exists) {
          await scoresRef.child(playerId).set(0);
        }
        print('📊 Real-time score update: $playerId = $currentScore (wrong answer)');
      }
      
      // Also update match metadata if not exists
      final matchMetaRef = databaseRef!.child('matchScores').child(matchId);
      final match = currentMatch.value;
      if (match != null) {
        final metaSnapshot = await matchMetaRef.child('matchId').get();
        if (!metaSnapshot.exists) {
          await matchMetaRef.update({
            'matchId': matchId,
            'createdBy': match.createdBy,
            'players': match.players.map((p) => {
              'userId': p.userId,
              'userName': p.userName,
              'userAvatar': p.userAvatar,
              'userEmail': p.userEmail,
            }).toList(),
          });
        }
      }
    } catch (e) {
      print('❌ Error updating real-time score: $e');
    }
  }

  /// Move to next question
  Future<void> nextQuestion(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final match = currentMatch.value;
      if (match == null) return;

      final nextIndex = match.currentQuestionIndex + 1;
      
      if (nextIndex >= match.questions.length) {
        // Match completed
        await endMatch(matchId);
      } else {
        final matchRef = databaseRef!.child('matches').child(matchId);
        // Set question start time for timer synchronization
        await matchRef.update({
          'currentQuestionIndex': nextIndex,
          'currentQuestionStartTime': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error moving to next question: $e');
    }
  }

  /// End match and calculate scores
  Future<void> endMatch(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final match = currentMatch.value;
      if (match == null) return;

      final matchRef = databaseRef!.child('matches').child(matchId);
      final answersSnapshot = await matchRef.child('answers').get();
      
      final scores = <String, int>{};
      
      // Initialize all players with 0 score
      for (var player in match.players) {
        scores[player.userId] = 0;
      }
      
      if (answersSnapshot.exists) {
        final answers = answersSnapshot.value as Map<dynamic, dynamic>;
        print('📋 Found answers for ${answers.length} players');
        print('📋 Match has ${match.questions.length} questions');
        print('📋 Match players: ${match.players.map((p) => p.userId).toList()}');
        
        // Calculate scores for each player
        for (var playerEntry in answers.entries) {
          final playerId = playerEntry.key.toString();
          final playerAnswers = playerEntry.value as Map<dynamic, dynamic>;
          print('📋 Player $playerId has ${playerAnswers.length} answers');
          print('📋 Player $playerId answer keys: ${playerAnswers.keys.toList()}');
          print('📋 Match has ${match.questions.length} questions');
          print('📋 Match question IDs: ${match.questions.map((q) => q.questionId).toList()}');
          
          int playerScore = 0;

          // Check each question in the match
          for (var question in match.questions) {
            final questionId = question.questionId;
            final answerDataRaw = playerAnswers[questionId];
            
            print('🔍 Checking Player $playerId, Question $questionId...');
            print('   Answer data type: ${answerDataRaw.runtimeType}');
            print('   Answer data: $answerDataRaw');
            
            if (answerDataRaw != null) {
              // Handle different data types from Firebase
              int selectedIndex = -1;
              
              try {
                if (answerDataRaw is Map) {
                  final answerData = Map<String, dynamic>.from(answerDataRaw);
                  selectedIndex = answerData['selectedIndex'] as int? ?? -1;
                  print('   Parsed from Map: selectedIndex = $selectedIndex');
                } else if (answerDataRaw is int) {
                  selectedIndex = answerDataRaw;
                  print('   Parsed from int: selectedIndex = $selectedIndex');
                } else if (answerDataRaw is String) {
                  selectedIndex = int.tryParse(answerDataRaw) ?? -1;
                  print('   Parsed from String: selectedIndex = $selectedIndex');
                } else {
                  print('   ⚠️ Unknown data type: ${answerDataRaw.runtimeType}');
                }
              } catch (e) {
                print('⚠️ Error parsing answer data for $playerId, question $questionId: $e');
                selectedIndex = -1;
              }
              
              // Only count if answer is correct (and not -1 which means no answer)
              if (selectedIndex >= 0 && selectedIndex == question.correctAnswerIndex) {
                playerScore++;
                print('✅ Player $playerId: Question ${questionId} - Correct! (selected: $selectedIndex, correct: ${question.correctAnswerIndex})');
              } else if (selectedIndex >= 0) {
                print('❌ Player $playerId: Question ${questionId} - Wrong (selected: $selectedIndex, correct: ${question.correctAnswerIndex})');
              } else {
                print('⚠️ Player $playerId: Question ${questionId} - No answer (selected: $selectedIndex)');
              }
            } else {
              print('⚠️ Player $playerId: Question ${questionId} - No answer data (key not found in playerAnswers)');
            }
          }

          scores[playerId] = playerScore;
          print('📊 Calculated score for $playerId: $playerScore/${match.questions.length}');
          print('📊 Updated scores map: $scores');
        }
      } else {
        print('⚠️ No answers found in match, all players get 0 score');
      }
      
      // Ensure all players have scores (even if they didn't answer)
      for (var player in match.players) {
        if (!scores.containsKey(player.userId)) {
          scores[player.userId] = 0;
        }
      }
      
      print('📊 Final scores: $scores');
      print('📊 Scores map details:');
      for (var entry in scores.entries) {
        print('   ${entry.key}: ${entry.value}');
      }

      // Find winner (player with highest score)
      String? winnerId;
      if (scores.isNotEmpty) {
        final sortedScores = scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        winnerId = sortedScores.first.key;
        print('🏆 Winner: $winnerId with score ${sortedScores.first.value}');
      }

      // Update matchScores collection with final scores and metadata
      // Scores are already being updated in real-time, just finalize here
      final scoresRef = databaseRef!.child('matchScores').child(matchId);
      
      // Get current scores from matchScores (real-time updated)
      final currentScoresSnapshot = await scoresRef.child('scores').get();
      Map<String, int> finalScores = {};
      
      if (currentScoresSnapshot.exists) {
        final currentScores = currentScoresSnapshot.value as Map<dynamic, dynamic>?;
        if (currentScores != null) {
          for (var entry in currentScores.entries) {
            final playerId = entry.key.toString();
            final scoreValue = entry.value;
            if (scoreValue is int) {
              finalScores[playerId] = scoreValue;
            } else if (scoreValue is String) {
              finalScores[playerId] = int.tryParse(scoreValue) ?? 0;
            }
          }
        }
      }
      
      // If real-time scores not found, use calculated scores
      if (finalScores.isEmpty) {
        finalScores = scores;
        await scoresRef.child('scores').set(scores);
        print('💾 Saved calculated scores to matchScores: $scores');
      } else {
        // Ensure all players have scores
        for (var player in match.players) {
          if (!finalScores.containsKey(player.userId)) {
            finalScores[player.userId] = 0;
          }
        }
        // Update with final calculated scores (in case of any discrepancy)
        await scoresRef.child('scores').set(finalScores);
        print('💾 Updated matchScores with final scores: $finalScores');
      }
      
      // Update match metadata
      await scoresRef.update({
        'matchId': matchId,
        'createdBy': match.createdBy,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'winnerId': winnerId ?? '',
        'players': match.players.map((p) => {
          'userId': p.userId,
          'userName': p.userName,
          'userAvatar': p.userAvatar,
          'userEmail': p.userEmail,
        }).toList(),
      });
      
      print('✅ Final scores in matchScores: $finalScores');
      
      // Verify scores were saved correctly
      final verifySnapshot = await scoresRef.child('scores').get();
      if (verifySnapshot.exists) {
        final savedScores = verifySnapshot.value;
        print('✅ Verified scores in DB: $savedScores');
      } else {
        print('❌ ERROR: Scores not found after saving!');
      }

      // Delete match from matches collection after saving scores
      // Scores are now in matchScores collection, so match can be deleted
      await matchRef.remove();
      print('✅ Match deleted from matches collection (scores saved in matchScores)');
      
      // Clear current match from controller
      currentMatch.value = null;

      // Update leaderboard for ALL players based on their scores (async)
      if (scores.isNotEmpty) {
        print('📊 Updating leaderboard for ${scores.length} players...');
        
        // Ensure LeaderboardController is registered
        if (!Get.isRegistered<LeaderboardController>()) {
          Get.put(LeaderboardController());
        }
        
        final leaderboardController = Get.find<LeaderboardController>();
        
        // Update scores for all players
        final updatePromises = <Future>[];
        for (var scoreEntry in scores.entries) {
          final playerId = scoreEntry.key;
          final playerScore = scoreEntry.value; // Number of correct answers
          final pointsToAdd = playerScore * 10; // 10 points per correct answer
          final isWinner = playerId == winnerId;
          
          print('📊 Player $playerId: Score = $playerScore correct answers = $pointsToAdd points, Winner: $isWinner');
          
          // Get player info from match
          final player = match.players.firstWhereOrNull((p) => p.userId == playerId);
          if (player != null) {
            // Update each player's score (points = correct answers * 10)
            updatePromises.add(
              leaderboardController.updateUserScoreForUserId(
                userId: playerId,
                userName: player.userName,
                userEmail: player.userEmail,
                userAvatar: player.userAvatar,
                points: pointsToAdd,
                testPassed: true,
                isMatchWinner: isWinner, // Pass winner flag
              ).then((_) async {
                print('✅ Updated leaderboard for $playerId: +$pointsToAdd points, Winner: $isWinner');
                
                // Also update user profile with totalPoints and matchesWon
                try {
                  final userRef = databaseRef!.child('users').child(playerId);
                  final userSnapshot = await userRef.get();
                  
                  if (userSnapshot.exists) {
                    final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                    final currentProfilePoints = (userData['totalPoints'] as int? ?? 0);
                    final currentMatchesWon = (userData['matchesWon'] as int? ?? 0);
                    
                    // Get opponent info for match history (all opponents)
                    final opponents = match.players.where((p) => p.userId != playerId).toList();
                    final opponentsList = <Map<String, dynamic>>[];
                    for (var p in opponents) {
                      opponentsList.add({
                        'userId': p.userId,
                        'userName': p.userName,
                        'userAvatar': p.userAvatar,
                        'score': scores[p.userId] ?? 0,
                      });
                    }
                    
                    // Get highest scoring opponent for display
                    Map<String, dynamic>? topOpponent;
                    if (opponentsList.isNotEmpty) {
                      topOpponent = opponentsList.first;
                      for (var opp in opponentsList) {
                        if ((opp['score'] as int) > (topOpponent!['score'] as int)) {
                          topOpponent = opp;
                        }
                      }
                    }
                    
                    // Create match history entry
                    final matchHistoryEntry = {
                      'matchId': matchId,
                      'opponents': opponentsList, // All opponents
                      'opponent': topOpponent != null ? {
                        'userId': topOpponent['userId'],
                        'userName': topOpponent['userName'],
                        'userAvatar': topOpponent['userAvatar'],
                      } : null, // Top opponent for display
                      'myScore': playerScore,
                      'opponentScore': topOpponent != null 
                          ? (topOpponent['score'] as int)
                          : 0,
                      'isWinner': isWinner,
                      'pointsEarned': pointsToAdd,
                      'completedAt': DateTime.now().millisecondsSinceEpoch,
                    };
                    
                    // Get existing match history
                    final matchHistory = (userData['matchHistory'] as List<dynamic>?) ?? [];
                    final updatedHistory = List<Map<String, dynamic>>.from(
                      matchHistory.map((e) => Map<String, dynamic>.from(e))
                    );
                    
                    // Add new match to history (at the beginning)
                    updatedHistory.insert(0, matchHistoryEntry);
                    
                    // Keep only last 50 matches
                    if (updatedHistory.length > 50) {
                      updatedHistory.removeRange(50, updatedHistory.length);
                    }
                    
                    await userRef.update({
                      'totalPoints': currentProfilePoints + pointsToAdd,
                      'matchesWon': isWinner ? currentMatchesWon + 1 : currentMatchesWon,
                      'matchHistory': updatedHistory,
                      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                    });
                    print('✅ Updated profile for $playerId: Points=${currentProfilePoints + pointsToAdd}, Wins=${isWinner ? currentMatchesWon + 1 : currentMatchesWon}');
                  } else {
                    // Set initial values if not exists
                    final opponents = match.players.where((p) => p.userId != playerId).toList();
                    final opponentsList = <Map<String, dynamic>>[];
                    for (var p in opponents) {
                      opponentsList.add({
                        'userId': p.userId,
                        'userName': p.userName,
                        'userAvatar': p.userAvatar,
                        'score': scores[p.userId] ?? 0,
                      });
                    }
                    
                    Map<String, dynamic>? topOpponent;
                    if (opponentsList.isNotEmpty) {
                      topOpponent = opponentsList.first;
                      for (var opp in opponentsList) {
                        if ((opp['score'] as int) > (topOpponent!['score'] as int)) {
                          topOpponent = opp;
                        }
                      }
                    }
                    
                    final matchHistoryEntry = {
                      'matchId': matchId,
                      'opponents': opponentsList,
                      'opponent': topOpponent != null ? {
                        'userId': topOpponent['userId'],
                        'userName': topOpponent['userName'],
                        'userAvatar': topOpponent['userAvatar'],
                      } : null,
                      'myScore': playerScore,
                      'opponentScore': topOpponent != null 
                          ? (topOpponent['score'] as int)
                          : 0,
                      'isWinner': isWinner,
                      'pointsEarned': pointsToAdd,
                      'completedAt': DateTime.now().millisecondsSinceEpoch,
                    };
                    
                    await userRef.update({
                      'totalPoints': pointsToAdd,
                      'matchesWon': isWinner ? 1 : 0,
                      'matchHistory': [matchHistoryEntry],
                      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                    });
                    print('✅ Set initial profile for $playerId: Points=$pointsToAdd, Wins=${isWinner ? 1 : 0}');
                  }
                } catch (e) {
                  print('⚠️ Error updating profile for $playerId: $e');
                }
              }).catchError((e) {
                print('❌ Error updating leaderboard for $playerId: $e');
              }),
            );
          } else {
            print('⚠️ Player $playerId not found in match players list');
          }
        }
        
        // Wait for all updates to complete
        print('⏳ Waiting for all leaderboard updates to complete...');
        await Future.wait(updatePromises);
        print('✅ All leaderboard updates completed');
        
        // Reload leaderboard once after all updates
        await leaderboardController.loadLeaderboard();
        print('✅ Leaderboard reloaded');
      } else {
        print('⚠️ No scores to update in leaderboard');
      }
    } catch (e) {
      print('Error ending match: $e');
    }
  }
  
  /// Delete match from database (called after showing results)
  Future<void> deleteMatch(String matchId) async {
    if (!isFirebaseAvailable) return;
    
    try {
      final matchRef = databaseRef!.child('matches').child(matchId);
      await matchRef.remove();
      
      // Reset state
      currentMatch.value = null;
      isResultScreenShown.value = false;
      allPlayersAnswers.clear();
      playerAnswers.clear();
      _matchListener?.onDisconnect();
      _answersListener?.onDisconnect();
      
      print('Match $matchId deleted successfully');
    } catch (e) {
      print('Error deleting match: $e');
    }
  }

  /// Leave match
  Future<void> leaveMatch(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final matchRef = databaseRef!.child('matches').child(matchId);
      final snapshot = await matchRef.get();

      if (snapshot.exists) {
        final matchData = Map<String, dynamic>.from(snapshot.value as Map);
        final players = (matchData['players'] as List<dynamic>?)
                ?.map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p)))
                .toList() ??
            [];

        players.removeWhere((p) => p.userId == currentUser.uid);

        if (players.isEmpty) {
          // Delete match if no players left
          await matchRef.remove();
        } else {
          await matchRef.update({
            'players': players.map((p) => p.toJson()).toList(),
          });
        }
      }

      _matchListener?.onDisconnect();
      currentMatch.value = null;
    } catch (e) {
      print('Error leaving match: $e');
    }
  }

  /// Send match invitation notification to specific user
  Future<void> _sendMatchInvitationNotification(
    String opponentUserId,
    String matchId,
    String inviterName,
  ) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // Get opponent's FCM token from Firebase
      final userSnapshot = await databaseRef!.child('users').child(opponentUserId).get();
      if (!userSnapshot.exists) return;

      final userData = Map<String, dynamic>.from(userSnapshot.value as Map<dynamic, dynamic>);
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('Opponent FCM token not found');
        return;
      }

      // Store notification in Firebase
      await databaseRef!.child('notifications').child(opponentUserId).child(matchId).set({
        'matchId': matchId,
        'inviterId': currentUserId,
        'inviterName': inviterName,
        'type': 'match_invitation',
        'status': 'pending', // pending, accepted, rejected
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Send notification with accept/reject actions
      await SendNotificationService.sendNotificationUsingApi(
        token: fcmToken,
        title: 'Match Invitation',
        body: '$inviterName wants to play a match with you!',
        data: {
          'type': 'match_invitation',
          'matchId': matchId,
          'inviterId': currentUserId,
          'inviterName': inviterName,
        },
      );
    } catch (e) {
      print('Error sending match invitation notification: $e');
    }
  }
  
  /// Send public match notifications to all available users
  Future<void> _sendPublicMatchNotifications(
    String matchId,
    String creatorName,
  ) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Get all users from leaderboard (exclude current user)
      final snapshot = await databaseRef!.child('leaderboard').child('allTime').get();
      if (!snapshot.exists) return;

      final allUsers = snapshot.value as Map<dynamic, dynamic>?;
      if (allUsers == null) return;

      // Get FCM tokens for all users
      final notificationPromises = <Future>[];
      
      for (var userEntry in allUsers.entries) {
        final userId = userEntry.key.toString();
        
        // Skip current user
        if (userId == currentUserId) continue;
        
        // Skip dummy users
        if (userId.startsWith('dummy_user_')) continue;

        // Get user's FCM token
        final userSnapshot = await databaseRef!.child('users').child(userId).get();
        if (!userSnapshot.exists) continue;

        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final fcmToken = userData['fcmToken'] as String?;

             if (fcmToken != null && fcmToken.isNotEmpty) {
               // Store notification in Firebase
               notificationPromises.add(
                 databaseRef!.child('notifications').child(userId).child(matchId).set({
                   'matchId': matchId,
                   'inviterId': currentUserId,
                   'inviterName': creatorName,
                   'type': 'match_invitation',
                   'status': 'pending', // pending, accepted, rejected
                   'createdAt': DateTime.now().millisecondsSinceEpoch,
                 }),
               );
               
               // Send notification with accept/reject actions
               notificationPromises.add(
                 SendNotificationService.sendNotificationUsingApi(
                   token: fcmToken,
                   title: 'New Match Available!',
                   body: '$creatorName created a new match. Join now!',
                   data: {
                     'type': 'match_invitation',
                     'matchId': matchId,
                     'inviterId': currentUserId,
                     'inviterName': creatorName,
                   },
                 ),
               );
             }
      }

      // Send all notifications in parallel
      await Future.wait(notificationPromises);
      print('Sent ${notificationPromises.length} match notifications');
    } catch (e) {
      print('Error sending public match notifications: $e');
    }
  }

  /// Handle match invitation accept/reject
  Future<void> handleMatchInvitationResponse({
    required String matchId,
    required bool accepted,
  }) async {
    if (!isFirebaseAvailable) {
      AppToast.showError('Firebase not available');
      return;
    }

    try {
      if (accepted) {
        // Mark notification as accepted in Firebase
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          await databaseRef!.child('notifications').child(currentUserId).child(matchId).update({
            'status': 'accepted',
            'acceptedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        // Join the match
        await joinMatch(matchId);
        AppToast.showSuccess('Match invitation accepted!');
      } else {
        // Reject - Mark notification as rejected in Firebase
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          // Update notification status in Firebase (use set to ensure it's saved)
          await databaseRef!.child('notifications').child(currentUserId).child(matchId).set({
            'matchId': matchId,
            'status': 'rejected',
            'rejectedAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        // Also add to local rejected list
        rejectedMatchIds.add(matchId);
        
        // Immediately remove from pending invitations list (don't wait for listener)
        pendingInvitations.removeWhere((invitation) => invitation['matchId'] == matchId);
        
        print('✅ User rejected match invitation: $matchId (notification marked as rejected)');
        AppToast.showInfo('Match invitation rejected');
        
        // Force refresh pending invitations to ensure sync with Firebase
        // This will trigger _updatePendingInvitations which reads fresh data
        final currentUserIdForRefresh = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserIdForRefresh != null) {
          await _updatePendingInvitations(currentUserIdForRefresh);
        }
      }
    } catch (e) {
      print('❌ Error handling match invitation response: $e');
      print('   Stack trace: ${StackTrace.current}');
      AppToast.showError('Failed to handle invitation: ${e.toString()}');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Update notification in Firebase
      await databaseRef!.child('notifications').child(currentUserId).child(matchId).update({
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update local list
      final invitationIndex = pendingInvitations.indexWhere(
        (inv) => inv['matchId'] == matchId,
      );
      if (invitationIndex != -1) {
        pendingInvitations[invitationIndex]['isRead'] = true;
        pendingInvitations.refresh();
      }

      if (kDebugMode) {
        print('✅ Notification marked as read: $matchId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Mark all pending invitations as read
      final updatePromises = <Future>[];
      for (var invitation in pendingInvitations) {
        final matchId = invitation['matchId'] as String;
        final isRead = invitation['isRead'] ?? false;
        
        if (!isRead) {
          updatePromises.add(
            databaseRef!.child('notifications').child(currentUserId).child(matchId).update({
              'isRead': true,
              'readAt': DateTime.now().millisecondsSinceEpoch,
            }),
          );
          
          // Update local list
          invitation['isRead'] = true;
        }
      }

      await Future.wait(updatePromises);
      pendingInvitations.refresh();

      if (kDebugMode) {
        print('✅ All notifications marked as read');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete match (creator only) - Completely removes from database
  Future<void> closeMatch(String matchId) async {
    if (!isFirebaseAvailable) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final matchRef = databaseRef!.child('matches').child(matchId);
      final snapshot = await matchRef.get();

      if (!snapshot.exists) return;

      final matchData = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      final createdBy = matchData['createdBy']?.toString() ?? '';
      final currentUserId = currentUser.uid;

      // Only creator can delete - simple check
      if (createdBy.isNotEmpty && createdBy != currentUserId) {
        // Not the creator, don't delete
        return;
      }

      // Delete match from database
      await matchRef.remove();

      // Refresh matches list
      loadActiveMatches();

      AppToast.showSuccess('Match deleted');
    } catch (e) {
      AppToast.showError('Failed to delete match');
    }
  }
}

