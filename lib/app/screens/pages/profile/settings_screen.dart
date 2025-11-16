import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/app_toast.dart';
import 'package:afn_test/app/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
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
          'Settings',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             

              SizedBox(height: 24.h),

              // Notifications Section
              Obx(() => _buildSection(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    icon: Iconsax.notification,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications about your progress',
                    value: controller.pushNotifications.value,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      controller.togglePushNotifications(value);
                      AppToast.showSuccess('Push notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  _buildSwitchTile(
                    icon: Iconsax.notification_bing,
                    title: 'Quiz Reminders',
                    subtitle: 'Get reminded to take quizzes',
                    value: controller.quizReminders.value,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      controller.toggleQuizReminders(value);
                      AppToast.showSuccess('Quiz reminders ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  _buildSwitchTile(
                    icon: Iconsax.ranking,
                    title: 'Leaderboard Updates',
                    subtitle: 'Notifications when your rank changes',
                    value: controller.leaderboardUpdates.value,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      controller.toggleLeaderboardUpdates(value);
                      AppToast.showSuccess('Leaderboard updates ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                ],
              )),

              SizedBox(height: 24.h),

              // App Preferences
              Obx(() => _buildSection(
                title: 'App Preferences',
                children: [
                  _buildListTile(
                    icon: Iconsax.moon,
                    title: 'Theme',
                    subtitle: controller.themeDisplayName,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showThemeDialog(context, controller);
                    },
                  ),
                ],
              )),

              SizedBox(height: 24.h),

              // Data & Storage
              Obx(() {
                final subtitle = controller.hasDownloadedData.value
                    ? '${controller.downloadedQuestionsCount.value} questions, ${controller.downloadedTestsCount.value} tests downloaded'
                    : 'Download your quiz history';
                
                return _buildSection(
                  title: 'Data & Storage',
                  children: [
                    _buildListTile(
                      icon: Iconsax.document_download,
                      title: 'Download Data',
                      subtitle: subtitle,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _downloadData(context, controller);
                      },
                    ),
                    if (controller.hasDownloadedData.value)
                      _buildListTile(
                        icon: Iconsax.trash,
                        title: 'Clear Downloaded Data',
                        subtitle: 'Delete all downloaded MCQs',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _clearDownloadedData(context, controller);
                        },
                      ),
                    _buildListTile(
                      icon: Iconsax.trash,
                      title: 'Clear Cache',
                      subtitle: 'Free up storage space',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _clearCache(context);
                      },
                    ),
                  ],
                );
              }),

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

  /// Show theme selection dialog
  void _showThemeDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Select Theme',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => RadioListTile<String>(
                title: Text(
                  'Light',
                  style: AppTextStyles.label16.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                value: 'light',
                groupValue: controller.themeMode.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.setThemeMode(value);
                    Navigator.of(context).pop();
                    AppToast.showSuccess('Theme changed to Light');
                  }
                },
                activeColor: AppColors.primaryTeal,
              )),
              Obx(() => RadioListTile<String>(
                title: Text(
                  'Dark',
                  style: AppTextStyles.label16.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                value: 'dark',
                groupValue: controller.themeMode.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.setThemeMode(value);
                    Navigator.of(context).pop();
                    AppToast.showSuccess('Theme changed to Dark');
                  }
                },
                activeColor: AppColors.primaryTeal,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.label16.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Download MCQs data
  Future<void> _downloadData(BuildContext context, SettingsController controller) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
              SizedBox(height: 16.h),
              Text(
                'Downloading MCQs...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );

      final result = await controller.downloadMCQs();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result['success'] == true) {
          AppToast.showSuccess(
            'Downloaded ${result['questionsCount']} questions, ${result['testsCount']} tests, ${result['topicsCount']} topics, ${result['categoriesCount']} categories',
          );
          // UI will auto-update via Obx since observables are updated
        } else {
          AppToast.showError(result['message'] ?? 'Failed to download data');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        AppToast.showError('Failed to download data: $e');
      }
    }
  }

  /// Clear downloaded data
  Future<void> _clearDownloadedData(BuildContext context, SettingsController controller) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Clear Downloaded Data',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all downloaded MCQs? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.label16.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.label16.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryTeal,
          ),
        ),
      );

      final success = await controller.clearDownloadedMCQs();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          AppToast.showSuccess('Downloaded data cleared successfully');
          // UI will auto-update via Obx since observables are updated
        } else {
          AppToast.showError('Failed to clear downloaded data');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        AppToast.showError('Failed to clear downloaded data: $e');
      }
    }
  }

  /// Clear app cache
  Future<void> _clearCache(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryTeal,
          ),
        ),
      );

      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        AppToast.showSuccess('Cache cleared successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        AppToast.showError('Failed to clear cache: $e');
      }
    }
  }
}

