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
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Pending Invitations Badge
          Obx(() {
            final pendingCount = controller.pendingInvitations.length;
            if (pendingCount == 0) return SizedBox.shrink();
            
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Iconsax.notification),
                  color: AppColors.primaryTeal,
                  onPressed: () {
                    _showPendingInvitations(context, controller);
                  },
                ),
                if (pendingCount > 0)
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
                        '$pendingCount',
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
                          GestureDetector(
                            onTap: ()async{
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
          
          // Create new match
          final matchId = await controller.createPublicMatch();
          
          // Close loading dialog
          Get.back();
          
          if (matchId != null) {
            // Refresh matches list
            await controller.loadActiveMatches();
            // Navigate to lobby
            Get.toNamed('/match-lobby', arguments: {'matchId': matchId});
          }
                            },
                            child: Text(
                              'Create a match to get started!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                         
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
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

  void _showPendingInvitations(BuildContext context, MatchController controller) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pending Invitations',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() {
              if (controller.pendingInvitations.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text(
                    'No pending invitations',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.pendingInvitations.length,
                itemBuilder: (context, index) {
                  final invitation = controller.pendingInvitations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentYellowGreenLight,
                      child: Icon(Icons.person, color: AppColors.primaryTeal),
                    ),
                    title: Text(invitation['inviterName'] as String),
                    subtitle: Text('Wants to play a match'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                            controller.handleMatchInvitationResponse(
                              matchId: invitation['matchId'] as String,
                              accepted: false,
                            );
                          },
                          child: Text('Reject'),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                            controller.handleMatchInvitationResponse(
                              matchId: invitation['matchId'] as String,
                              accepted: true,
                            );
                            Get.toNamed('/match-lobby', arguments: {
                              'matchId': invitation['matchId'] as String,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Accept'),
                        ),
                      ],
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

