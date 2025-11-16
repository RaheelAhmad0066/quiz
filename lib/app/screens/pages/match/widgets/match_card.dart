import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

/// Match Card Widget - Shows match info with creator details
class MatchCard extends StatelessWidget {
  final String matchId;
  final String creatorName;
  final String? creatorAvatar;
  final int creatorPoints;
  final int? creatorWins; // Number of matches won
  final int? creatorRank; // User's rank
  final int? creatorTestsCompleted; // Number of tests completed
  final String status;
  final bool isLocked;
  final bool isClosed;
  final int playerCount;
  final int maxPlayers;
  final String? winnerName;
  final bool isCreator;
  final VoidCallback? onJoin;
  final VoidCallback? onClose;
  final VoidCallback? onTap; // Tap to view lobby

  const MatchCard({
    Key? key,
    required this.matchId,
    required this.creatorName,
    this.creatorAvatar,
    required this.creatorPoints,
    this.creatorWins,
    this.creatorRank,
    this.creatorTestsCompleted,
    required this.status,
    required this.isLocked,
    required this.isClosed,
    required this.playerCount,
    required this.maxPlayers,
    this.winnerName,
    this.isCreator = false,
    this.onJoin,
    this.onClose,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with creator info
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Creator Avatar
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.accentYellowGreenLight,
                  backgroundImage: creatorAvatar != null && creatorAvatar!.isNotEmpty
                      ? NetworkImage(creatorAvatar!)
                      : null,
                  child: creatorAvatar == null || creatorAvatar!.isEmpty
                      ? Icon(
                          Iconsax.user,
                          color: AppColors.primaryTeal,
                          size: 24.sp,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                // Creator Name and Points
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creatorName,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Stats Row - Points, Wins, Rank, Tests Completed
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellowGreenLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Points
                            _buildStatChip(
                              icon: Iconsax.star,
                              value: '$creatorPoints',
                              label: 'Points',
                              iconColor: AppColors.accentYellowGreen,
                            ),
                            // Wins
                            if (creatorWins != null)
                              _buildStatChip(
                                icon: Icons.emoji_events,
                                value: '$creatorWins',
                                label: 'Wins',
                                iconColor: Colors.amber,
                              ),
                            // Rank
                            if (creatorRank != null)
                              _buildStatChip(
                                icon: Iconsax.ranking,
                                value: '#$creatorRank',
                                label: 'Rank',
                                iconColor: AppColors.primaryTeal,
                              ),
                            // Tests Completed
                            if (creatorTestsCompleted != null)
                              _buildStatChip(
                                icon: Iconsax.book,
                                value: '$creatorTestsCompleted',
                                label: 'Tests',
                                iconColor: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button (creator only)
                if (isCreator && !isClosed && status == 'waiting')
                  IconButton(
                    icon: Icon(
                      Iconsax.close_circle,
                      color: Colors.red,
                      size: 24.sp,
                    ),
                    onPressed: onClose,
                    tooltip: 'Close Match',
                  ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1, color: AppColors.backgroundLight),
          
          // Match Status and Players
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player Count (Status removed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$playerCount/$maxPlayers Players',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Winner (if completed)
                if (status == 'completed' && winnerName != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellowGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: AppColors.accentYellowGreen,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Winner: $winnerName',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Join Button (if applicable)
                if (onJoin != null && !isClosed && !isLocked && status == 'waiting' && !isCreator) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Join Match',
                        style: AppTextStyles.label16.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: iconColor,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.label14.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

}

