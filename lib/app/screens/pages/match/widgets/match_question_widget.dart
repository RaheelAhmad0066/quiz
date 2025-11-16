import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/models/match/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

/// Match Question Widget
class MatchQuestionWidget extends StatelessWidget {
  final MatchQuestion question;
  final int? selectedIndex;
  final Function(int) onAnswerSelected;
  final Map<String, Map<String, int>>? allPlayersAnswers;
  final List<MatchPlayer>? matchPlayers;
  final String? currentUserId;

  const MatchQuestionWidget({
    Key? key,
    required this.question,
    this.selectedIndex,
    required this.onAnswerSelected,
    this.allPlayersAnswers,
    this.matchPlayers,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          width: double.infinity,
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
          child: Text(
            question.question,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Options
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedIndex == index;
          
          // Get players who selected this option
          List<String> playersWhoSelected = [];
          if (allPlayersAnswers != null && matchPlayers != null) {
            for (var player in matchPlayers!) {
              final playerAnswers = allPlayersAnswers![player.userId];
              if (playerAnswers != null) {
                final selectedIdx = playerAnswers[question.questionId];
                if (selectedIdx == index) {
                  playersWhoSelected.add(player.userName);
                }
              }
            }
          }

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: InkWell(
              onTap: () => onAnswerSelected(index),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryTeal
                        : AppColors.accentYellowGreen,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.accentYellowGreenLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: AppTextStyles.label14.copyWith(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show players who selected this option
                    if (playersWhoSelected.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: playersWhoSelected.map((playerName) {
                          final isCurrentUser = matchPlayers?.firstWhere(
                            (p) => p.userName == playerName,
                            orElse: () => MatchPlayer(
                              userId: '',
                              userName: '',
                              userEmail: '',
                            ),
                          ).userId == currentUserId;
                          
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.profile_circle,
                                  size: 12.sp,
                                  color: isSelected ? Colors.white : AppColors.primaryTeal,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  isCurrentUser ? 'You' : playerName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

