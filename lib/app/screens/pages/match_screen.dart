import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/auth_required_dialog.dart';
import 'package:afn_test/app/screens/pages/match/screens/match_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Match Screen - Redirects to MatchListScreen
class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if guest user
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AuthRequiredDialog.show();
      });
      // Return empty scaffold while dialog shows
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Container(),
      );
    }

    // Use the new MatchListScreen
    return const MatchListScreen();
  }
}

