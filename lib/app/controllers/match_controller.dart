import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_widgets/app_toast.dart';

/// Match Controller - For finding and challenging other users
class MatchController extends GetxController {
  DatabaseReference? _databaseRef;
  
  DatabaseReference get databaseRef {
    if (_databaseRef == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _databaseRef = FirebaseDatabase.instance.ref();
        }
      } catch (e) {
        print('Firebase Database not initialized: $e');
      }
    }
    return _databaseRef!;
  }
  
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty && _databaseRef != null;
    } catch (e) {
      return false;
    }
  }

  final RxList<Map<String, dynamic>> availableUsers = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAvailableUsers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load available users from leaderboard
  Future<void> loadAvailableUsers() async {
    if (!isFirebaseAvailable) return;

    try {
      isLoading.value = true;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final snapshot = await databaseRef.child('leaderboard').child('allTime').get();

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          availableUsers.value = snapshotValue.entries
              .where((entry) => entry.key.toString() != currentUserId)
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

  /// Challenge a user
  Future<void> challengeUser(String userId) async {
    try {
      AppToast.showInfo('Challenge sent! Waiting for response...');
      // TODO: Implement challenge/match logic
    } catch (e) {
      AppToast.showError('Failed to send challenge');
    }
  }
}

