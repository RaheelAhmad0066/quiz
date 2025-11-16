import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/match/match_controller.dart';
import 'package:afn_test/app/models/match/match_model.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/screens/dashbord/dashboard_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';

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
  late ConfettiController _confettiController;
  final Rx<Map<String, int>?> matchScores = Rx<Map<String, int>?>(null);
  final RxBool isLoadingScores = false.obs;
  final RxList<MatchPlayer> matchPlayers = <MatchPlayer>[].obs;
  final RxString matchCreatedBy = ''.obs;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<MatchController>();
    
    // Ensure match listener is active to get latest data
    controller.listenToMatch(widget.matchId);
    
    // Load scores from separate collection
    _loadMatchScores();
    
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

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchScores() async {
    try {
      isLoadingScores.value = true;
      final databaseRef = FirebaseDatabase.instance.ref();
      final scoresSnapshot = await databaseRef.child('matchScores').child(widget.matchId).get();
      
      if (scoresSnapshot.exists) {
        final scoresData = Map<String, dynamic>.from(scoresSnapshot.value as Map);
        
        // Load scores
        final scores = scoresData['scores'] as Map<dynamic, dynamic>?;
        if (scores != null) {
          matchScores.value = Map<String, int>.from(
            scores.map((key, value) => MapEntry(key.toString(), value as int))
          );
          print('✅ Loaded scores from matchScores collection: ${matchScores.value}');
        }
        
        // Load players from matchScores
        final players = scoresData['players'] as List<dynamic>?;
        if (players != null) {
          matchPlayers.value = players
              .map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList();
          print('✅ Loaded ${matchPlayers.length} players from matchScores');
        }
        
        // Load createdBy
        if (scoresData['createdBy'] != null) {
          matchCreatedBy.value = scoresData['createdBy']?.toString() ?? '';
        }
      } else {
        print('⚠️ Scores not found in matchScores collection, trying match...');
        // Fallback: try to get from match (for backward compatibility)
        final matchSnapshot = await databaseRef.child('matches').child(widget.matchId).get();
        if (matchSnapshot.exists) {
          final matchData = Map<String, dynamic>.from(matchSnapshot.value as Map);
          final scores = matchData['scores'] as Map<dynamic, dynamic>?;
          if (scores != null) {
            matchScores.value = Map<String, int>.from(
              scores.map((key, value) => MapEntry(key.toString(), value as int))
            );
            print('✅ Loaded scores from match (fallback): ${matchScores.value}');
          }
          
          // Load players from match
          final players = matchData['players'] as List<dynamic>?;
          if (players != null) {
            matchPlayers.value = players
                .map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
                .toList();
          }
        }
      }
    } catch (e) {
      print('❌ Error loading match scores: $e');
    } finally {
      isLoadingScores.value = false;
    }
  }

  void _navigateToLeaderboard() async {
    // Match already deleted in endMatch, just navigate
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
          final scores = matchScores.value;
          final players = matchPlayers;
          
          // Wait for data to load
          if (isLoadingScores.value) {
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

          // Get players from matchScores (since match is deleted) or from current match
          final allPlayersWithScores = <MatchPlayer>[];
          
          if (players.isNotEmpty) {
            // Use players from matchScores (match already deleted)
            allPlayersWithScores.addAll(players);
          } else if (match != null && match.players.isNotEmpty) {
            // Fallback: use players from current match if available
            allPlayersWithScores.addAll(match.players);
          }
          
          // If no players, show loading
          if (allPlayersWithScores.isEmpty) {
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
          
          // If scores not loaded yet, try loading again
          if (scores == null || scores.isEmpty) {
            if (!isLoadingScores.value) {
              _loadMatchScores();
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading scores...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort players by score (from matchScores collection)
          final sortedPlayers = allPlayersWithScores.toList()
            ..sort((a, b) {
              final scoreA = scores[a.userId] ?? 0;
              final scoreB = scores[b.userId] ?? 0;
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
          final winnerScore = scores[winner.userId] ?? 0;
          final currentUserScore = scores[currentUserId ?? ''] ?? 0;

          // Trigger confetti if winner
          if (isWinner) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _confettiController.play();
            });
          }

          return Stack(
            children: [
              SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // Winner/Loser Card with Animation
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
                              : [Colors.red.shade400, Colors.red.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isWinner ? AppColors.primaryTeal : Colors.red)
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
                            isWinner ? '🎉 You Won! 🎉' : '😔 You Lost',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            isWinner 
                                ? 'Score: $winnerScore/10' 
                                : 'Your Score: $currentUserScore/10',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isWinner) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Winner: ${winner.userName}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
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
                  final score = scores[player.userId] ?? 0;
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
          ),
              // Confetti overlay for winner
              if (isWinner)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 3.14 / 2, // Top to bottom
                    maxBlastForce: 5,
                    minBlastForce: 2,
                    emissionFrequency: 0.05,
                    numberOfParticles: 50,
                    gravity: 0.1,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.yellow,
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

