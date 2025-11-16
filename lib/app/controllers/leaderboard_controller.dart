import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import '../models/leaderboard_model.dart';
import '../app_widgets/app_toast.dart';

/// Leaderboard Controller
class LeaderboardController extends GetxController {
  DatabaseReference? _databaseRef;
  
  DatabaseReference? get databaseRef {
    if (_databaseRef == null) {
      try { 
        if (Firebase.apps.isNotEmpty) {
          _databaseRef = FirebaseDatabase.instance.ref();
        } else {
          print('Firebase apps is empty');
          return null;
        }
      } catch (e) {
        print('Firebase Database not initialized: $e');
        return null;
      }
    }
    return _databaseRef;
  }
  
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty && databaseRef != null;
    } catch (e) {
      print('Firebase availability check failed: $e');
      return false;
    }
  }

  // Observable List - Single leaderboard for all users
  final RxList<LeaderboardModel> leaderboard = <LeaderboardModel>[].obs;
  
  // Loading States
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
  }

  /// Get current leaderboard
  List<LeaderboardModel> get currentLeaderboard {
    return leaderboard;
  }

  /// Get top 3 players - reordered for podium (2nd, 1st, 3rd)
  List<LeaderboardModel> get topThree {
    final list = currentLeaderboard.take(3).toList();
    
    if (list.isEmpty) return [];
    if (list.length == 1) return [list[0]]; // Just 1st
    if (list.length == 2) return [list[1], list[0]]; // 2nd, 1st
    
    // 3 or more: return [2nd, 1st, 3rd]
    return [list[1], list[0], list[2]];
  }

  /// Load leaderboard from Firebase - All users ranking
  Future<void> loadLeaderboard() async {
    if (!isFirebaseAvailable) {
      print('Firebase not available, skipping leaderboard load');
      isLoading.value = false;
      return;
    }
    
    try {
      isLoading.value = true;
      
      final ref = databaseRef;
      if (ref == null) {
        print('Database reference is null');
        leaderboard.clear();
        isLoading.value = false;
        return;
      }
      
      // Load from allTime leaderboard (all users)
      final snapshot = await ref.child('leaderboard').child('allTime').get();
      
      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          
          leaderboard.value = snapshotValue.entries.map((entry) {
            return LeaderboardModel.fromJson(
              Map<String, dynamic>.from(entry.value),
              entry.key.toString(),
              currentUserId: currentUserId,
            );
          }).toList();
          
          // Sort by total points (descending)
          leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        }
      } else {
        leaderboard.clear();
      }
      
    } catch (e) {
      print('Error loading leaderboard: $e');
      if (Firebase.apps.isNotEmpty) {
        AppToast.showError('Failed to load leaderboard');
      }
      leaderboard.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user score after completing a test (for current user)
  Future<void> updateUserScore({
    required int points,
    required bool testPassed,
  }) async {
    if (!isFirebaseAvailable) {
      print('Firebase not available, cannot update score');
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, cannot update score');
      return;
    }
    
    try {
      final userId = user.uid;
      final userName = user.displayName ?? 'User';
      final userEmail = user.email ?? '';
      final userAvatar = user.photoURL;
      
      // Update all time leaderboard
      await _updateScore(
        path: 'leaderboard/allTime/$userId',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userAvatar: userAvatar,
        points: points,
        testPassed: testPassed,
      );
      
      // Reload leaderboard to update rankings
      await loadLeaderboard();
      
    } catch (e) {
      print('Error updating user score: $e');
    }
  }

  /// Update user score for a specific user ID (for match results)
  Future<void> updateUserScoreForUserId({
    required String userId,
    required String userName,
    required String userEmail,
    String? userAvatar,
    required int points,
    required bool testPassed,
  }) async {
    if (!isFirebaseAvailable) {
      print('Firebase not available, cannot update score');
      return;
    }
    
    try {
      // Update all time leaderboard for specific user
      await _updateScore(
        path: 'leaderboard/allTime/$userId',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userAvatar: userAvatar,
        points: points,
        testPassed: testPassed,
      );
      
      // Note: loadLeaderboard() will be called once after all player updates
      // in match_controller.dart to avoid multiple reloads
      
    } catch (e) {
      print('Error updating user score for $userId: $e');
    }
  }

  /// Update score at specific path
  Future<void> _updateScore({
    required String path,
    required String userId,
    required String userName,
    required String userEmail,
    String? userAvatar,
    required int points,
    required bool testPassed,
  }) async {
    try {
      final dbRef = databaseRef;
      if (dbRef == null) {
        print('❌ Database reference is null, cannot update score');
        return;
      }
      
      final ref = dbRef.child(path);
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        // User exists, update their score
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final currentPoints = (data['totalPoints'] ?? 0) as int;
        final testsCompleted = (data['testsCompleted'] ?? 0) as int;
        final newPoints = testPassed ? currentPoints + points : currentPoints;
        
        print('📊 Updating score for $userId:');
        print('   Current points: $currentPoints');
        print('   Points to add: $points');
        print('   New points: $newPoints');
        print('   Test passed: $testPassed');
        
        await ref.update({
          'totalPoints': newPoints,
          'testsCompleted': testsCompleted + 1,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('✅ Score updated successfully for $userId');
      } else {
        // New user, create entry
        final initialPoints = testPassed ? points : 0;
        print('📊 Creating new leaderboard entry for $userId:');
        print('   Initial points: $initialPoints');
        print('   Test passed: $testPassed');
        
        await ref.set({
          'userName': userName,
          'userEmail': userEmail,
          'userAvatar': userAvatar,
          'totalPoints': initialPoints,
          'testsCompleted': 1,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('✅ New leaderboard entry created for $userId');
      }
    } catch (e) {
      print('❌ Error updating score at $path: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Add dummy data to leaderboard for testing
  Future<void> addDummyData() async {
    if (!isFirebaseAvailable) {
      print('Firebase not available, cannot add dummy data');
      return;
    }

    try {
      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        return;
      }

      final dummyUsers = [
        {
          'userName': 'Bryan Wolf',
          'userEmail': 'bryan.wolf@example.com',
          'userAvatar': null,
          'totalPoints': 430,
          'testsCompleted': 15,
          'lastUpdated': DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Meghan Jessica',
          'userEmail': 'meghan.jessica@example.com',
          'userAvatar': null,
          'totalPoints': 400,
          'testsCompleted': 12,
          'lastUpdated': DateTime.now().subtract(Duration(days: 2)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Alex Turner',
          'userEmail': 'alex.turner@example.com',
          'userAvatar': null,
          'totalPoints': 380,
          'testsCompleted': 10,
          'lastUpdated': DateTime.now().subtract(Duration(days: 3)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Marsha Fisher',
          'userEmail': 'marsha.fisher@example.com',
          'userAvatar': null,
          'totalPoints': 360,
          'testsCompleted': 9,
          'lastUpdated': DateTime.now().subtract(Duration(days: 4)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Juanita Cormier',
          'userEmail': 'juanita.cormier@example.com',
          'userAvatar': null,
          'totalPoints': 350,
          'testsCompleted': 8,
          'lastUpdated': DateTime.now().subtract(Duration(days: 5)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Tamara Schmidt',
          'userEmail': 'tamara.schmidt@example.com',
          'userAvatar': null,
          'totalPoints': 330,
          'testsCompleted': 7,
          'lastUpdated': DateTime.now().subtract(Duration(days: 6)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Ricardo Veum',
          'userEmail': 'ricardo.veum@example.com',
          'userAvatar': null,
          'totalPoints': 320,
          'testsCompleted': 6,
          'lastUpdated': DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Gary Sanford',
          'userEmail': 'gary.sanford@example.com',
          'userAvatar': null,
          'totalPoints': 310,
          'testsCompleted': 5,
          'lastUpdated': DateTime.now().subtract(Duration(days: 8)).millisecondsSinceEpoch,
        },
        {
          'userName': 'Becky Bartell',
          'userEmail': 'becky.bartell@example.com',
          'userAvatar': null,
          'totalPoints': 300,
          'testsCompleted': 4,
          'lastUpdated': DateTime.now().subtract(Duration(days: 9)).millisecondsSinceEpoch,
        },
      ];

      final ref = dbRef.child('leaderboard').child('allTime');
      
      // Add each dummy user
      for (var i = 0; i < dummyUsers.length; i++) {
        final userId = 'dummy_user_${i + 1}';
        await ref.child(userId).set(dummyUsers[i]);
        print('Added dummy user: ${dummyUsers[i]['userName']}');
      }

      print('✅ Dummy data added successfully!');
      
      // Reload leaderboard
      await loadLeaderboard();
      
    } catch (e) {
      print('Error adding dummy data: $e');
    }
  }
}