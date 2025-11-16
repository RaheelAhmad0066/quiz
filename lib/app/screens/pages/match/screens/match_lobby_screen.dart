import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/match/match_controller.dart';
import 'package:afn_test/app/models/match/match_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'match_play_screen.dart';

/// Match Lobby Screen - Waiting for 4 players
class MatchLobbyScreen extends StatefulWidget {
  final String matchId;

  const MatchLobbyScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<MatchController>();
    // Start listening to match only once
    controller.listenToMatch(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return WillPopScope(
      onWillPop: () async {
        // Mark that user manually left lobby
        controller.markUserLeftLobby();
        // Handle back button
        controller.loadActiveMatches();
        return true; // Allow back navigation
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: AppColors.primaryTeal),
            onPressed: () async {
              // Mark that user manually left lobby
              controller.markUserLeftLobby();
              // Don't leave match, just go back
              // Refresh matches list when going back
              controller.loadActiveMatches();
              Get.back();
            },
          ),
          title: Text(
            'Match Lobby',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Obx(() {
          final match = controller.currentMatch.value;
          if (match == null) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
            );
          }

          // Check if match started
          if (match.status == MatchStatus.inProgress || match.status == MatchStatus.starting) {
            // Navigate to play screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.off(() => MatchPlayScreen(matchId: widget.matchId));
            });
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
            );
          }

          final isCreator = match.createdBy == currentUserId;
          final isFull = match.players.length >= 4;

          return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Match Info Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Waiting for Players',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${match.players.length}/4 Players',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    LinearProgressIndicator(
                      value: match.players.length / 4,
                      backgroundColor: AppColors.accentYellowGreenLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Players List
              Text(
                'Players',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 16.h),

              // Players Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.2,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  if (index < match.players.length) {
                    final player = match.players[index];
                    final isCurrentUser = player.userId == currentUserId;

                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppColors.primaryTeal
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isCurrentUser
                              ? AppColors.primaryTeal
                              : AppColors.accentYellowGreen,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30.r,
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
                                          size: 30.sp,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: isCurrentUser
                                        ? AppColors.primaryTeal
                                        : AppColors.primaryTeal,
                                    size: 30.sp,
                                  ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            isCurrentUser ? 'You' : player.userName,
                            style: AppTextStyles.label14.copyWith(
                              color: isCurrentUser
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Empty slot
                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellowGreenLight,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.accentYellowGreen,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.user_add,
                            color: AppColors.primaryTeal,
                            size: 40.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Waiting...',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              SizedBox(height: 32.h),

              // Start Match Button (only for creator when full)
              if (isCreator && isFull)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.startMatch(widget.matchId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Start Match',
                      style: AppTextStyles.label16.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else if (!isFull)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellowGreenLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.clock,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Waiting for ${4 - match.players.length} more player(s)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        }),
      ),
    );
  }
}

