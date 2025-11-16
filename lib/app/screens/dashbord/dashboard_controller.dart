import 'package:afn_test/app/screens/pages/home_screen.dart';
import 'package:afn_test/app/screens/pages/match_screen.dart';
import 'package:afn_test/app/screens/pages/leaderboard_screen.dart';
import 'package:afn_test/app/screens/pages/profile/profile_screen.dart';
import 'package:afn_test/app/controllers/quiz_controller.dart';
import 'package:afn_test/app/app_widgets/auth_required_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class DashboardController extends GetxController {
  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize QuizController for HomeScreen
    if (!Get.isRegistered<QuizController>()) {
      Get.lazyPut(() => QuizController());
    }
  }

  List<Widget> get pages => [
    HomeScreen(),
    const MatchScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  /// Check if user is guest
  bool get isGuest {
    return FirebaseAuth.instance.currentUser == null;
  }

  void changePage(int index) {
    // Restrict access for guest users
    if (isGuest && index != 0) {
      // Index 0 is Home, allow it
      // Index 1 is Match, 2 is Leaderboard, 3 is Profile - restrict these
      AuthRequiredDialog.show();
      return;
    }
    currentIndex.value = index;
  }
}
