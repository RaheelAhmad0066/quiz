import 'dart:convert';
import 'package:afn_test/app/services/prefferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsController extends GetxController {
  final Preferences _prefs = Get.find<Preferences>();

  // Keys for SharedPreferences
  static const String _keyPushNotifications = 'push_notifications';
  static const String _keyQuizReminders = 'quiz_reminders';
  static const String _keyLeaderboardUpdates = 'leaderboard_updates';
  static const String _keyTheme = 'theme_mode'; // 'light' or 'dark'
  static const String _keyDownloadedMCQs = 'downloaded_mcqs'; // Downloaded MCQs

  // Observable values
  final RxBool pushNotifications = true.obs;
  final RxBool quizReminders = false.obs;
  final RxBool leaderboardUpdates = true.obs;
  final RxString themeMode = 'light'.obs;
  
  // Downloaded MCQs observables
  final RxBool hasDownloadedData = false.obs;
  final RxInt downloadedQuestionsCount = 0.obs;
  final RxInt downloadedTestsCount = 0.obs;
  final RxInt downloadedTopicsCount = 0.obs;
  final RxInt downloadedCategoriesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadDownloadedMCQsInfo();
  }

  /// Load settings from SharedPreferences
  void _loadSettings() {
    pushNotifications.value = _prefs.getBool(_keyPushNotifications) ?? true;
    quizReminders.value = _prefs.getBool(_keyQuizReminders) ?? false;
    leaderboardUpdates.value = _prefs.getBool(_keyLeaderboardUpdates) ?? true;
    themeMode.value = _prefs.getString(_keyTheme) ?? 'light';
  }

  /// Load downloaded MCQs info
  void _loadDownloadedMCQsInfo() {
    final counts = _getDownloadedMCQsCount();
    hasDownloadedData.value = counts['questions']! > 0 || counts['tests']! > 0;
    downloadedQuestionsCount.value = counts['questions'] ?? 0;
    downloadedTestsCount.value = counts['tests'] ?? 0;
    downloadedTopicsCount.value = counts['topics'] ?? 0;
    downloadedCategoriesCount.value = counts['categories'] ?? 0;
  }

  /// Get downloaded MCQs count (internal method)
  Map<String, int> _getDownloadedMCQsCount() {
    try {
      final jsonString = _prefs.getString(_keyDownloadedMCQs);
      if (jsonString == null || jsonString.isEmpty) {
        return {
          'questions': 0,
          'tests': 0,
          'topics': 0,
          'categories': 0,
        };
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'questions': (data['questions'] as List?)?.length ?? 0,
        'tests': (data['tests'] as List?)?.length ?? 0,
        'topics': (data['topics'] as List?)?.length ?? 0,
        'categories': (data['categories'] as List?)?.length ?? 0,
      };
    } catch (e) {
      print('Error getting downloaded MCQs count: $e');
      return {
        'questions': 0,
        'tests': 0,
        'topics': 0,
        'categories': 0,
      };
    }
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications(bool value) async {
    pushNotifications.value = value;
    await _prefs.setBool(_keyPushNotifications, value);
  }

  /// Toggle quiz reminders
  Future<void> toggleQuizReminders(bool value) async {
    quizReminders.value = value;
    await _prefs.setBool(_keyQuizReminders, value);
  }

  /// Toggle leaderboard updates
  Future<void> toggleLeaderboardUpdates(bool value) async {
    leaderboardUpdates.value = value;
    await _prefs.setBool(_keyLeaderboardUpdates, value);
  }

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    themeMode.value = mode;
    await _prefs.setString(_keyTheme, mode);
    
    // Update app theme
    if (mode == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.light);
    }
  }

  /// Get current theme mode display name
  String get themeDisplayName {
    return themeMode.value == 'dark' ? 'Dark' : 'Light';
  }

  /// Download and save MCQs locally
  Future<Map<String, dynamic>> downloadMCQs() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Please login first',
        };
      }

      final databaseRef = FirebaseDatabase.instance.ref();
      
      // Get all questions from Firebase
      final questionsSnapshot = await databaseRef.child('questions').get();
      final testsSnapshot = await databaseRef.child('tests').get();
      final topicsSnapshot = await databaseRef.child('topics').get();
      final categoriesSnapshot = await databaseRef.child('categories').get();

      final downloadedData = <String, dynamic>{
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': currentUser.uid,
        'questions': <Map<String, dynamic>>[],
        'tests': <Map<String, dynamic>>[],
        'topics': <Map<String, dynamic>>[],
        'categories': <Map<String, dynamic>>[],
      };

      // Save questions
      if (questionsSnapshot.exists) {
        final questionsValue = questionsSnapshot.value;
        if (questionsValue is Map) {
          final questions = questionsValue;
          for (var entry in questions.entries) {
            try {
              final value = entry.value;
              if (value is Map) {
                // Safely convert to Map<String, dynamic>
                final questionData = <String, dynamic>{};
                for (var mapEntry in value.entries) {
                  questionData[mapEntry.key.toString()] = mapEntry.value;
                }
                downloadedData['questions']!.add({
                  'id': entry.key.toString(),
                  ...questionData,
                });
              } else {
                print('⚠️ Skipping question ${entry.key}: value is not a Map (${value.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error processing question ${entry.key}: $e');
            }
          }
        }
      }

      // Save tests
      if (testsSnapshot.exists) {
        final testsValue = testsSnapshot.value;
        if (testsValue is Map) {
          final tests = testsValue;
          for (var entry in tests.entries) {
            try {
              final value = entry.value;
              if (value is Map) {
                // Safely convert to Map<String, dynamic>
                final testData = <String, dynamic>{};
                for (var mapEntry in value.entries) {
                  testData[mapEntry.key.toString()] = mapEntry.value;
                }
                downloadedData['tests']!.add({
                  'id': entry.key.toString(),
                  ...testData,
                });
              } else {
                print('⚠️ Skipping test ${entry.key}: value is not a Map (${value.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error processing test ${entry.key}: $e');
            }
          }
        }
      }

      // Save topics
      if (topicsSnapshot.exists) {
        final topicsValue = topicsSnapshot.value;
        if (topicsValue is Map) {
          final topics = topicsValue;
          for (var entry in topics.entries) {
            try {
              final value = entry.value;
              if (value is Map) {
                // Safely convert to Map<String, dynamic>
                final topicData = <String, dynamic>{};
                for (var mapEntry in value.entries) {
                  topicData[mapEntry.key.toString()] = mapEntry.value;
                }
                downloadedData['topics']!.add({
                  'id': entry.key.toString(),
                  ...topicData,
                });
              } else {
                print('⚠️ Skipping topic ${entry.key}: value is not a Map (${value.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error processing topic ${entry.key}: $e');
            }
          }
        }
      }

      // Save categories
      if (categoriesSnapshot.exists) {
        final categoriesValue = categoriesSnapshot.value;
        if (categoriesValue is Map) {
          final categories = categoriesValue;
          for (var entry in categories.entries) {
            try {
              final value = entry.value;
              if (value is Map) {
                // Safely convert to Map<String, dynamic>
                final categoryData = <String, dynamic>{};
                for (var mapEntry in value.entries) {
                  categoryData[mapEntry.key.toString()] = mapEntry.value;
                }
                downloadedData['categories']!.add({
                  'id': entry.key.toString(),
                  ...categoryData,
                });
              } else {
                print('⚠️ Skipping category ${entry.key}: value is not a Map (${value.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error processing category ${entry.key}: $e');
            }
          }
        }
      }

      // Save to SharedPreferences
      final jsonString = jsonEncode(downloadedData);
      await _prefs.setString(_keyDownloadedMCQs, jsonString);

      // Also save to file system for backup
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/downloaded_mcqs.json');
        await file.writeAsString(jsonString);
      } catch (e) {
        print('Error saving to file: $e');
      }

      // Update observables
      final questionsCount = (downloadedData['questions'] as List).length;
      final testsCount = (downloadedData['tests'] as List).length;
      final topicsCount = (downloadedData['topics'] as List).length;
      final categoriesCount = (downloadedData['categories'] as List).length;
      
      hasDownloadedData.value = questionsCount > 0 || testsCount > 0;
      downloadedQuestionsCount.value = questionsCount;
      downloadedTestsCount.value = testsCount;
      downloadedTopicsCount.value = topicsCount;
      downloadedCategoriesCount.value = categoriesCount;

      return {
        'success': true,
        'message': 'MCQs downloaded successfully',
        'questionsCount': questionsCount,
        'testsCount': testsCount,
        'topicsCount': topicsCount,
        'categoriesCount': categoriesCount,
      };
    } catch (e) {
      print('Error downloading MCQs: $e');
      return {
        'success': false,
        'message': 'Failed to download MCQs: $e',
      };
    }
  }


  /// Clear downloaded MCQs
  Future<bool> clearDownloadedMCQs() async {
    try {
      // Clear from SharedPreferences
      await _prefs.remove(_keyDownloadedMCQs);

      // Clear from file system
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/downloaded_mcqs.json');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }

      // Update observables
      hasDownloadedData.value = false;
      downloadedQuestionsCount.value = 0;
      downloadedTestsCount.value = 0;
      downloadedTopicsCount.value = 0;
      downloadedCategoriesCount.value = 0;

      return true;
    } catch (e) {
      print('Error clearing downloaded MCQs: $e');
      return false;
    }
  }
}

