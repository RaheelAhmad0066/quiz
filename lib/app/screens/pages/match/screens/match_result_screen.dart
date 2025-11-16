import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/match/match_controller.dart';
import 'package:afn_test/app/models/match/match_model.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/screens/dashbord/dashboard_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

/// Match Result Screen - Shows results and updates leaderboard
class MatchResultScreen extends StatefulWidget {
  final String matchId;

  const MatchResultScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<MatchController>();
    
    // Ensure match listener is active to get latest data with scores
    controller.listenToMatch(widget.matchId);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLeaderboard() async {
    final controller = Get.find<MatchController>();
    // Delete match from database
    await controller.deleteMatch(widget.matchId);
    // Navigate to dashboard (leaderboard tab)
    Get.offAllNamed(AppRoutes.dashboard);
    // Switch to leaderboard tab (index 2)
    final dashboardController = Get.find<DashboardController>();
    dashboardController.changePage(2);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Obx(() {
          final match = controller.currentMatch.value;
          
          // Wait for match data to load
          if (match == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading results...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Get all players with scores
          final allPlayersWithScores = <MatchPlayer>[];
          
          // First, add all players from match.players
          if (match.players.isNotEmpty) {
            for (var player in match.players) {
              allPlayersWithScores.add(player);
            }
          }
          
          // Also check scores map for any players not in match.players (fallback)
          // This ensures we show players even if match.players is empty
          if (match.scores.isNotEmpty) {
            for (var scoreEntry in match.scores.entries) {
              final playerId = scoreEntry.key;
              // Only add if not already in list
              if (!allPlayersWithScores.any((p) => p.userId == playerId)) {
                // Try to get player name from Firebase or use fallback
                String playerName = 'Player ${playerId.substring(0, playerId.length > 8 ? 8 : playerId.length)}';
                
                // Create a temporary player entry for display
                allPlayersWithScores.add(MatchPlayer(
                  userId: playerId,
                  userName: playerName,
                  userEmail: '$playerId@temp.com',
                  userAvatar: null,
                  joinedAt: DateTime.now(),
                ));
              }
            }
          }
          
          // If still no players, show loading (match data might still be updating)
          if (allPlayersWithScores.isEmpty && match.scores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading match results...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort players by score
          final sortedPlayers = allPlayersWithScores.toList()
            ..sort((a, b) {
              final scoreA = match.scores[a.userId] ?? 0;
              final scoreB = match.scores[b.userId] ?? 0;
              return scoreB.compareTo(scoreA);
            });

          // Final check - if still empty, show error
          if (sortedPlayers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: AppColors.primaryTeal),
                  SizedBox(height: 16.h),
                  Text(
                    'No players found',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Match data is still loading...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final winner = sortedPlayers.first;
          final isWinner = winner.userId == currentUserId;
          final winnerScore = match.scores[winner.userId] ?? 0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // Winner Card with Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWinner
                              ? [AppColors.primaryTeal, AppColors.primaryTealLight]
                              : [Colors.grey.shade300, Colors.grey.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isWinner ? AppColors.primaryTeal : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 30,
                            offset: Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Animated Icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Transform.rotate(
                                  angle: value * 0.2,
                                  child: Icon(
                                    isWinner ? Iconsax.star5 : Icons.sentiment_dissatisfied,
                                    color: Colors.white,
                                    size: 80.sp,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            isWinner ? '🎉 You Won! 🎉' : '${winner.userName} Won!',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Score: $winnerScore/10',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isWinner) ...[
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '+${winnerScore * 10} Points',
                                style: AppTextStyles.label16.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Leaderboard
                Text(
                  'Match Results',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 16.h),

                // Players List
                ...sortedPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  final score = match.scores[player.userId] ?? 0;
                  final isCurrentUser = player.userId == currentUserId;
                  final isTopThree = index < 3;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? AppColors.primaryTeal
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: isTopThree
                          ? Border.all(
                              color: AppColors.accentYellowGreen,
                              width: 2,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: isTopThree
                                ? AppColors.accentYellowGreen
                                : AppColors.accentYellowGreenLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.label16.copyWith(
                                color: isTopThree
                                    ? AppColors.primaryTeal
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // Avatar
                        CircleAvatar(
                          radius: 25.r,
                          backgroundColor: isCurrentUser
                              ? Colors.white
                              : AppColors.accentYellowGreenLight,
                          child: player.userAvatar != null
                              ? ClipOval(
                                  child: Image.network(
                                    player.userAvatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        color: isCurrentUser
                                            ? AppColors.primaryTeal
                                            : AppColors.primaryTeal,
                                        size: 25.sp,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: isCurrentUser
                                      ? AppColors.primaryTeal
                                      : AppColors.primaryTeal,
                                  size: 25.sp,
                                ),
                        ),

                        SizedBox(width: 12.w),

                        // Name
                        Expanded(
                          child: Text(
                            isCurrentUser ? 'You' : player.userName,
                            style: AppTextStyles.label16.copyWith(
                              color: isCurrentUser
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Score
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.white
                                : AppColors.accentYellowGreenLight,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$score/10',
                            style: AppTextStyles.label14.copyWith(
                              color: isCurrentUser
                                  ? AppColors.primaryTeal
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                SizedBox(height: 32.h),

                // Go to Leaderboard Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToLeaderboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.ranking, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'View Leaderboard',
                          style: AppTextStyles.label16.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          );
        }),
      ),
    );
  }
}

