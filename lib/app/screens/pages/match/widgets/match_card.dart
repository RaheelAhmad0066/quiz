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
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Iconsax.star,
                            size: 14.sp,
                            color: AppColors.accentYellowGreen,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$creatorPoints points',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status, isLocked, isClosed).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status, isLocked, isClosed),
                            size: 14.sp,
                            color: _getStatusColor(status, isLocked, isClosed),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _getStatusText(status, isLocked, isClosed),
                            style: AppTextStyles.label14.copyWith(
                              color: _getStatusColor(status, isLocked, isClosed),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    // Player Count
                    Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$playerCount/$maxPlayers',
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

  Color _getStatusColor(String status, bool isLocked, bool isClosed) {
    if (isClosed) return Colors.grey;
    if (isLocked) return Colors.orange;
    switch (status.toLowerCase()) {
      case 'waiting':
        return AppColors.primaryTeal;
      case 'starting':
        return Colors.blue;
      case 'inprogress':
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return AppColors.accentYellowGreen;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status, bool isLocked, bool isClosed) {
    if (isClosed) return Iconsax.close_circle;
    if (isLocked) return Iconsax.lock;
    switch (status.toLowerCase()) {
      case 'waiting':
        return Iconsax.clock;
      case 'starting':
        return Iconsax.play;
      case 'inprogress':
      case 'in_progress':
        return Iconsax.play_circle;
      case 'completed':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  String _getStatusText(String status, bool isLocked, bool isClosed) {
    if (isClosed) return 'Closed';
    if (isLocked) return 'Locked';
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Waiting';
      case 'starting':
        return 'Starting';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}

