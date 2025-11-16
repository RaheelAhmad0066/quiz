import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final RxList<Map<String, dynamic>> matchHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingHistory = false.obs;

  @override
  void initState() {
    super.initState();
    _loadMatchHistory();
  }

  Future<void> _loadMatchHistory() async {
    try {
      isLoadingHistory.value = true;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final databaseRef = FirebaseDatabase.instance.ref();
      final userSnapshot = await databaseRef.child('users').child(currentUserId).get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final history = (userData['matchHistory'] as List<dynamic>?) ?? [];
        matchHistory.value = history
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      print('Error loading match history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppColors.primaryTeal),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Match History',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Obx(() {
        if (isLoadingHistory.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryTeal,
            ),
          );
        }

        if (matchHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.game,
                  size: 64.sp,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No matches yet',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Play matches to see your history here',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: matchHistory.length,
          itemBuilder: (context, index) {
            final match = matchHistory[index];
            final isWinner = match['isWinner'] as bool? ?? false;
            
            // Safely cast opponent
            final opponentRaw = match['opponent'];
            final opponent = opponentRaw != null 
                ? Map<String, dynamic>.from(opponentRaw as Map)
                : null;
            
            final myScore = match['myScore'] as int? ?? 0;
            final opponentScore = match['opponentScore'] as int? ?? 0;
            final opponentName = opponent?['userName'] as String? ?? 'Unknown';
            final opponentAvatar = opponent?['userAvatar'] as String?;
            final pointsEarned = match['pointsEarned'] as int? ?? 0;
            final completedAt = match['completedAt'] as int?;
            final matchDate = completedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(completedAt)
                : null;

            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
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
                  // Header with result
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isWinner 
                          ? Colors.green.shade50 
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: isWinner 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWinner ? Iconsax.tick_circle : Iconsax.close_circle,
                            color: isWinner 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWinner ? 'You Won!' : 'You Lost',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isWinner 
                                      ? Colors.green.shade700 
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (matchDate != null)
                                Text(
                                  '${matchDate.day}/${matchDate.month}/${matchDate.year}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isWinner)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '+$pointsEarned pts',
                              style: AppTextStyles.label14.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Score Table
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        // Table Header
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Player',
                                style: AppTextStyles.label14.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Score',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label14.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Points',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label14.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Divider(height: 1),
                        SizedBox(height: 12.h),
                        
                        // Your Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.r,
                                    backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primaryTeal,
                                      size: 18.sp,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'You',
                                      style: AppTextStyles.label16.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$myScore/10',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label16.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isWinner ? '+$pointsEarned' : '0',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label16.copyWith(
                                  color: isWinner 
                                      ? Colors.green.shade700 
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Divider(height: 1),
                        SizedBox(height: 12.h),
                        
                        // Opponent Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.r,
                                    backgroundColor: isWinner 
                                        ? Colors.red.shade100 
                                        : Colors.green.shade100,
                                    backgroundImage: opponentAvatar != null && opponentAvatar.isNotEmpty
                                        ? NetworkImage(opponentAvatar)
                                        : null,
                                    child: opponentAvatar == null || opponentAvatar.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color: isWinner 
                                                ? Colors.red.shade700 
                                                : Colors.green.shade700,
                                            size: 18.sp,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      opponentName,
                                      style: AppTextStyles.label16.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$opponentScore/10',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label16.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                !isWinner ? '+${opponentScore * 10}' : '0',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label16.copyWith(
                                  color: !isWinner 
                                      ? Colors.green.shade700 
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

