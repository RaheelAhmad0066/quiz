import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.primaryTeal),
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Settings',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Notifications Section
              _buildSection(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    icon: Iconsax.notification,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications about your progress',
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement notification toggle
                    },
                  ),
                  _buildSwitchTile(
                    icon: Iconsax.notification_bing,
                    title: 'Quiz Reminders',
                    subtitle: 'Get reminded to take quizzes',
                    value: false,
                    onChanged: (value) {
                      // TODO: Implement quiz reminders toggle
                    },
                  ),
                  _buildSwitchTile(
                    icon: Iconsax.ranking,
                    title: 'Leaderboard Updates',
                    subtitle: 'Notifications when your rank changes',
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement leaderboard notifications toggle
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // App Preferences
              _buildSection(
                title: 'App Preferences',
                children: [
                  _buildListTile(
                    icon: Iconsax.language_square,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      // TODO: Implement language selection
                    },
                  ),
                  _buildListTile(
                    icon: Iconsax.moon,
                    title: 'Theme',
                    subtitle: 'Light',
                    onTap: () {
                      // TODO: Implement theme selection
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Data & Storage
              _buildSection(
                title: 'Data & Storage',
                children: [
                  _buildListTile(
                    icon: Iconsax.document_download,
                    title: 'Download Data',
                    subtitle: 'Download your quiz history',
                    onTap: () {
                      // TODO: Implement data download
                      Get.snackbar('Info', 'Feature coming soon');
                    },
                  ),
                  _buildListTile(
                    icon: Iconsax.trash,
                    title: 'Clear Cache',
                    subtitle: 'Free up storage space',
                    onTap: () {
                      // TODO: Implement clear cache
                      Get.snackbar('Success', 'Cache cleared');
                    },
                  ),
                ],
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
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primaryTeal,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: AppTextStyles.label16.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryTeal,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primaryTeal,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: AppTextStyles.label16.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textLight,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }
}

