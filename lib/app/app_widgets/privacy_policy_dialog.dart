import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Privacy Policy Dialog
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static void show() {
    Get.dialog(
      const PrivacyPolicyDialog(),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Privacy Policy',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: '1. Information We Collect',
                      content:
                          'We collect information that you provide directly to us, including your name, email address, and quiz performance data. We also collect information automatically when you use our app, such as device information and usage data.',
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: '2. How We Use Your Information',
                      content:
                          'We use the information we collect to provide, maintain, and improve our services, process your quiz results, display leaderboard rankings, and communicate with you about your account.',
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: '3. Data Security',
                      content:
                          'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: '4. Third-Party Services',
                      content:
                          'We may use third-party services (such as Firebase) to help us operate our app and administer activities on our behalf. These services have their own privacy policies.',
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: '5. Your Rights',
                      content:
                          'You have the right to access, update, or delete your personal information at any time. You can also opt-out of certain communications from us.',
                    ),
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: '6. Contact Us',
                      content:
                          'If you have any questions about this Privacy Policy, please contact us at support@quizzax.com',
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'I Understand',
                    style: AppTextStyles.label16.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.label16.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

