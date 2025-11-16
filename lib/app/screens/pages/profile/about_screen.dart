import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(13.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              

              SizedBox(height: 24.h),

              // App Logo/Icon
              Center(
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppColors.accentYellowGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Iconsax.book_1,
                    size: 60.sp,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // App Name
              Center(
                child: Text(
                  'Quizzax',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Description
              _buildSection(
                title: 'About Quizzax',
                content:
                    'Quizzax is an interactive learning platform designed to help you improve your knowledge through personalized quizzes. Test your understanding, track your progress, and compete with others on the leaderboard.',
              ),

              SizedBox(height: 24.h),

              // Features
              _buildSection(
                title: 'Features',
                content: null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem('Interactive Quizzes', Iconsax.book),
                    _buildFeatureItem('Real-time Leaderboard', Iconsax.ranking),
                    _buildFeatureItem('Progress Tracking', Iconsax.chart),
                    _buildFeatureItem('Multiple Categories', Iconsax.category),
                    _buildFeatureItem('Challenge Friends', Iconsax.people),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Developer Info
              _buildSection(
                title: 'Developer',
                content: 'Developed with ❤️ for learners worldwide.',
              ),

              SizedBox(height: 24.h),

              // Copyright
              Center(
                child: Text(
                  '© 2024 Quizzax. All rights reserved.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    Widget? child,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (content != null) ...[
            SizedBox(height: 12.h),
            Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          if (child != null) ...[
            SizedBox(height: 12.h),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryTeal,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

