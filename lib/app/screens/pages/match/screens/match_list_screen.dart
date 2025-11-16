import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/spinkit_loadder.dart';
import 'package:afn_test/app/controllers/match/match_controller.dart';
import 'package:afn_test/app/screens/pages/match/widgets/match_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

/// Match List Screen - Shows all available users to challenge
class MatchListScreen extends StatelessWidget {
  const MatchListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MatchController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Active Matches',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Pending Invitations Badge (only unread)
          Obx(() {
            // Count only unread notifications
            final unreadCount = controller.pendingInvitations
                .where((inv) => !(inv['isRead'] ?? false))
                .length;
            if (unreadCount == 0) {
              // Show icon without badge if there are notifications but all are read
              if (controller.pendingInvitations.isEmpty) {
                return SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(Iconsax.notification),
                color: AppColors.primaryTeal,
                onPressed: () {
                  _showPendingInvitations(context, controller);
                },
              );
            }
            
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Iconsax.notification),
                  color: AppColors.primaryTeal,
                  onPressed: () {
                    _showPendingInvitations(context, controller);
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
     
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryTeal,
            ),
          );
        }

        return Column(
          children: [
            // Info Card - Other users can create matches
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.accentYellowGreenLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Iconsax.info_circle,
                    color: AppColors.primaryTeal,
                    size: 24.sp,
                  ),
                ),
                title: Text(
                  'Create Your Match',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    'Other users can also create matches. You can join their matches or create your own!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Iconsax.add_circle,
                    color: AppColors.primaryTeal,
                    size: 28.sp,
                  ),
                  onPressed: () {
                    // Show dialog to choose player count
                    _showPlayerCountDialog(context, controller);
                  },
                ),
              ),
            ),
            // Active Matches List
            Expanded(
              child: controller.activeMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.game,
                            size: 64.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No active matches',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Tap the button above to create a match!',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: controller.activeMatches.length,
                      itemBuilder: (context, index) {
                        final match = controller.activeMatches[index];
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                        final isCreator = match['createdBy'] == currentUserId;
                        final isLocked = match['isLocked'] as bool;
                        final isClosed = match['isClosed'] as bool;

                        return MatchCard(
                          matchId: match['matchId'] as String,
                          creatorName: match['creatorName'] as String,
                          creatorAvatar: match['creatorAvatar'] as String?,
                          creatorPoints: match['creatorPoints'] as int,
                          creatorWins: match['creatorWins'] as int?,
                          creatorRank: match['creatorRank'] as int?,
                          creatorTestsCompleted: match['creatorTestsCompleted'] as int?,
                          status: match['status'] as String,
                          isLocked: isLocked,
                          isClosed: isClosed,
                          playerCount: match['playerCount'] as int,
                          maxPlayers: match['maxPlayers'] as int,
                          winnerName: match['winnerName'] as String?,
                          isCreator: isCreator,
                          onTap: () {
                            // Navigate to lobby when card is tapped
                            Get.toNamed('/match-lobby', arguments: {
                              'matchId': match['matchId'] as String,
                            });
                          },
                          onJoin: isLocked || isClosed || isCreator
                              ? null
                              : () async {
                                  // Join match
                                  await controller.joinMatch(match['matchId'] as String);
                                  // Navigate to lobby
                                  Get.toNamed('/match-lobby', arguments: {
                                    'matchId': match['matchId'] as String,
                                  });
                                },
                          onClose: isCreator && !isClosed && match['status'] == 'waiting'
                              ? () async {
                                  // Close match
                                  await controller.closeMatch(match['matchId'] as String);
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      }),

    );
  }

  void _showPlayerCountDialog(BuildContext context, MatchController controller) {
    int? selectedPlayerCount;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Choose Players',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How many players do you want?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              // 2 Players Option
              InkWell(
                onTap: () {
                  setState(() {
                    selectedPlayerCount = 2;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: selectedPlayerCount == 2
                        ? AppColors.primaryTeal.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selectedPlayerCount == 2
                          ? AppColors.primaryTeal
                          : Colors.grey.withOpacity(0.3),
                      width: selectedPlayerCount == 2 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedPlayerCount == 2
                            ? Iconsax.tick_circle
                            : Icons.circle_outlined,
                        color: selectedPlayerCount == 2
                            ? AppColors.primaryTeal
                            : Colors.grey,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '2 Players',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: selectedPlayerCount == 2
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // 4 Players Option
              InkWell(
                onTap: () {
                  setState(() {
                    selectedPlayerCount = 4;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: selectedPlayerCount == 4
                        ? AppColors.primaryTeal.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selectedPlayerCount == 4
                          ? AppColors.primaryTeal
                          : Colors.grey.withOpacity(0.3),
                      width: selectedPlayerCount == 4 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedPlayerCount == 4
                            ? Iconsax.tick_circle
                            : Icons.circle_outlined,
                        color: selectedPlayerCount == 4
                            ? AppColors.primaryTeal
                            : Colors.grey,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '4 Players',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: selectedPlayerCount == 4
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedPlayerCount == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      // Show loading
                      Get.dialog(
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 200.w,
                                  child: SpinkitLoader(
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Creating match...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barrierDismissible: false,
                      );
                      
                      // Create new match with selected player count
                      final matchId = await controller.createPublicMatch(
                        maxPlayers: selectedPlayerCount!,
                      );
                      
                      // Close loading dialog
                      Get.back();
                      
                      if (matchId != null) {
                        // Refresh matches list
                        await controller.loadActiveMatches();
                        // Navigate to lobby
                        Get.toNamed('/match-lobby', arguments: {'matchId': matchId});
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Create',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingInvitations(BuildContext context, MatchController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 20.h,
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Obx(() {
                  final unreadCount = controller.pendingInvitations.length;
                  if (unreadCount == 0) return SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      // Mark all as read
                      controller.markAllNotificationsAsRead();
                    },
                    child: Text(
                      'Mark all as read',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  );
                }),
              ],
            ),
            SizedBox(height: 16.h),
            // Notifications List
            Obx(() {
              if (controller.pendingInvitations.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.notification,
                        size: 48.sp,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No pending invitations',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.pendingInvitations.length,
                itemBuilder: (context, index) {
                  final invitation = controller.pendingInvitations[index];
                  final isRead = invitation['isRead'] ?? false;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: isRead 
                          ? AppColors.backgroundLight 
                          : AppColors.accentYellowGreenLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isRead 
                            ? Colors.transparent 
                            : AppColors.primaryTeal.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                        radius: 24.r,
                        child: Icon(
                          Iconsax.game,
                          color: AppColors.primaryTeal,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        invitation['inviterName'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'wants to play a match with you',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      trailing: isRead
                          ? null
                          : Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () {
                        // Mark as read
                        controller.markNotificationAsRead(invitation['matchId'] as String);
                        // Navigate to match lobby
                        Get.back();
                        Get.toNamed('/match-lobby', arguments: {
                          'matchId': invitation['matchId'] as String,
                        });
                      },
                    ),
                  );
                },
              );
            }),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

