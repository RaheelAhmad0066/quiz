import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
      
      _invitationsListener!.onValue.listen((event) {
        if (event.snapshot.exists) {
          final matches = event.snapshot.value as Map<dynamic, dynamic>?;
          if (matches == null) {
            activeMatches.clear();
            return;
          }

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
            
            // Only show matches that are:
            // - Not closed
            // - Waiting or starting status
            // - Not full (less than 4 players) OR just completed (to show winner)
            // - Not created by current user (or show if user is already in it)
            final createdBy = matchData['createdBy']?.toString() ?? '';
            final isUserInMatch = players.any((p) => p.userId == currentUserId);
            final isUserCreator = createdBy == currentUserId;
            
            // Show match if:
            // 1. Not closed
            // 2. User is creator (to see their own matches) - ALWAYS show creator's matches
            // 3. OR (status is waiting AND not locked AND user not in match AND has space)
            // 4. OR (status is waiting AND user is in match) - show matches user joined
            // 5. OR (status is completed AND user was in match)
            final shouldShow = !isClosed && (
              isUserCreator || // Always show creator's matches
              (status == 'waiting' && !isLocked && !isUserInMatch && players.length < 4) || // Available matches
              (status == 'waiting' && isUserInMatch) || // Matches user joined
              (status == 'completed' && isUserInMatch) // Completed matches user was in
            );
            
            if (shouldShow) {
              // Get creator info from leaderboard
              final creatorId = createdBy;
              Map<String, dynamic> creatorInfo = {
                'userName': 'Unknown',
                'userAvatar': null,
                'totalPoints': 0,
              };
              
              // Try to get creator info from players first
              final creatorPlayer = players.firstWhereOrNull((p) => p.userId == creatorId);
              if (creatorPlayer != null) {
                creatorInfo = {
                  'userName': creatorPlayer.userName,
                  'userAvatar': creatorPlayer.userAvatar,
                  'totalPoints': 0, // Will fetch from leaderboard
                };
              }
              
              // Get creator points from leaderboard (async in stream - use then)
              databaseRef!.child('leaderboard').child('allTime').child(creatorId).get().then((snapshot) {
                if (snapshot.exists) {
                  final leaderboardData = Map<String, dynamic>.from(snapshot.value as Map);
                  creatorInfo['totalPoints'] = leaderboardData['totalPoints'] ?? 0;
                }
              }).catchError((e) {
                print('Error fetching creator points: $e');
              });
              
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
              
              matchesList.add({
                'matchId': matchId,
                'createdBy': creatorId,
                'creatorName': creatorInfo['userName'],
                'creatorAvatar': creatorInfo['userAvatar'],
                'creatorPoints': creatorInfo['totalPoints'],
                'status': status,
                'isLocked': isLocked,
                'isClosed': isClosed,
                'playerCount': players.length,
                'maxPlayers': 4,
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

      // Listen to matches where current user is invited but not yet joined
      _invitationsListener?.onDisconnect();
      _invitationsListener = databaseRef!.child('matches');
      
      _invitationsListener!.onValue.listen((event) async {
        if (event.snapshot.exists) {
          final matches = event.snapshot.value as Map<dynamic, dynamic>?;
          if (matches == null) {
            pendingInvitations.clear();
            return;
          }

          // Get all notifications for current user from Firebase
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
            
            // Check notification status from Firebase
            final notificationValue = notifications[matchId];
            final notificationData = notificationValue != null 
                ? Map<String, dynamic>.from(notificationValue as Map<dynamic, dynamic>)
                : null;
            final notificationStatus = notificationData?['status']?.toString() ?? 'pending';
            final isRejected = notificationStatus == 'rejected' || rejectedMatchIds.contains(matchId);
            final isAccepted = notificationStatus == 'accepted';
            
            // Show invitation if: invited, not joined, waiting, not rejected, not accepted, and not closed
            if (isInvited && isNotJoined && isWaiting && !isRejected && !isAccepted && isNotClosed) {
              // Get inviter info
              final inviterId = matchData['createdBy']?.toString() ?? '';
              final inviter = players.firstWhereOrNull((p) => p.userId == inviterId);
              
              invitations.add({
                'matchId': matchId,
                'inviterId': inviterId,
                'inviterName': inviter?.userName ?? 'Someone',
                'inviterAvatar': inviter?.userAvatar,
                'createdAt': matchData['createdAt'],
              });
            }
          }
          
          pendingInvitations.value = invitations;
        }
      });
    } catch (e) {
      print('Error loading pending invitations: $e');
    }
  }

  /// Create a new match (without opponent - for public matches)
  Future<String?> createPublicMatch({
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
      );

      // Save to Firebase
      final matchRef = databaseRef!.child('matches').push();
      final matchId = matchRef.key!;

      // Ensure createdBy is explicitly set
      final matchData = {
        ...match.toJson(),
        'matchId': matchId,
        'createdBy': currentUser.uid, // Explicitly set to ensure it's saved
      };
      
      print('✅ Creating public match with createdBy: ${currentUser.uid}');
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

      // Save to Firebase
      final matchRef = databaseRef!.child('matches').push();
      final matchId = matchRef.key!;

      // Ensure createdBy is explicitly set
      final matchData = {
        ...match.toJson(),
        'matchId': matchId,
        'createdBy': currentUser.uid, // Explicitly set to ensure it's saved
      };
      
      print('✅ Creating match with createdBy: ${currentUser.uid}');
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

      // Check if match is full
      if (players.length >= 4) {
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
      
      // Lock match if 4 players joined
      final shouldLock = players.length >= 4;

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
          } else if (match.status == MatchStatus.completed && !isResultScreenShown.value) {
            // Only navigate if not already on result screen
            if (currentRoute != '/match-result') {
              _lastNavigationTime = now;
              isResultScreenShown.value = true;
              Get.offNamed('/match-result', arguments: {'matchId': matchId});
            }
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

  /// Start match (when 4 players are ready)
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
    if (!isFirebaseAvailable) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final questionId = currentMatch.value?.questions[questionIndex].questionId ?? '';
      playerAnswers[questionId] = selectedIndex;

      // Update match with answer
      final matchRef = databaseRef!.child('matches').child(matchId);
      final answersRef = matchRef.child('answers').child(currentUser.uid).child(questionId);
      await answersRef.set({
        'selectedIndex': selectedIndex,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error submitting answer: $e');
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
      
      if (answersSnapshot.exists) {
        final answers = answersSnapshot.value as Map<dynamic, dynamic>;
        
        // Calculate scores for each player
        for (var playerEntry in answers.entries) {
          final playerId = playerEntry.key.toString();
          final playerAnswers = playerEntry.value as Map<dynamic, dynamic>;
          int playerScore = 0;

          for (var questionEntry in playerAnswers.entries) {
            final questionId = questionEntry.key.toString();
            final answerData = questionEntry.value as Map<dynamic, dynamic>;
            final selectedIndex = answerData['selectedIndex'] as int? ?? -1;

            // Find question
            final question = match.questions.firstWhereOrNull(
              (q) => q.questionId == questionId,
            );

            if (question != null && selectedIndex == question.correctAnswerIndex) {
              playerScore++;
            }
          }

          scores[playerId] = playerScore;
        }
      }

      // Update match with scores and status (unlock when completed)
      await matchRef.update({
        'status': MatchStatus.completed.toString(),
        'endedAt': DateTime.now().millisecondsSinceEpoch,
        'scores': scores,
        'isLocked': false, // Unlock when completed
      });

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
          
          print('📊 Player $playerId: Score = $playerScore correct answers = $pointsToAdd points');
          
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
              ).then((_) {
                print('✅ Updated leaderboard for $playerId: +$pointsToAdd points');
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
          // Update notification status in Firebase
          await databaseRef!.child('notifications').child(currentUserId).child(matchId).update({
            'status': 'rejected',
            'rejectedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        // Also add to local rejected list
        rejectedMatchIds.add(matchId);
        
        print('✅ User rejected match invitation: $matchId (notification marked as rejected)');
        AppToast.showInfo('Match invitation rejected');
        
        // Refresh pending invitations to remove this from user's list
        await loadPendingInvitations();
      }
    } catch (e) {
      print('❌ Error handling match invitation response: $e');
      print('   Stack trace: ${StackTrace.current}');
      AppToast.showError('Failed to handle invitation: ${e.toString()}');
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

