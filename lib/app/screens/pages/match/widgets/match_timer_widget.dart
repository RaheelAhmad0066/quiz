import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Match Timer Widget - Shows 10 second countdown
class MatchTimerWidget extends StatelessWidget {
  final int seconds;
  final VoidCallback? onTimeout;

  const MatchTimerWidget({
    Key? key,
    required this.seconds,
    this.onTimeout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowTime = seconds <= 3;

    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLowTime ? Colors.red : AppColors.primaryTeal,
        boxShadow: [
          BoxShadow(
            color: (isLowTime ? Colors.red : AppColors.primaryTeal).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$seconds',
          style: AppTextStyles.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 32.sp,
          ),
        ),
      ),
    );
  }
}

