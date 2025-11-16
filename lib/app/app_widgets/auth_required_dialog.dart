import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/custom_button.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Dialog shown when guest user tries to access restricted features
class AuthRequiredDialog extends StatelessWidget {
  const AuthRequiredDialog({super.key});

  static void show() {
    Get.dialog(
      const AuthRequiredDialog(),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.primaryTeal,
                size: 30.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              'Login Required',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 8.h),

            // Message
            Text(
              'Please login or sign up to access this feature.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h),

            // Login and Sign Up Buttons in Row
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Login',
                    backgroundColor: AppColors.primaryTeal,
                    textColor: AppColors.textWhite,
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.toNamed(AppRoutes.login);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: 'Sign Up',
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.toNamed(AppRoutes.signup);
                    },
                    
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

