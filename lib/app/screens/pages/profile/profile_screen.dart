import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/auth_required_dialog.dart';
import 'package:afn_test/app/app_widgets/contact_support_dialog.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/controllers/auth_controller.dart';
import 'package:afn_test/app/controllers/leaderboard_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if guest user
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AuthRequiredDialog.show();
      });
      // Return empty scaffold while dialog shows
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Container(),
      );
    }

    final authController = Get.put(AuthController());
    final leaderboardController = Get.find<LeaderboardController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Profile Header
              Column(
                children: [
                  // Avatar
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellowGreenLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal,
                        width: 3,
                      ),
                    ),
                    child: user?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: AppColors.primaryTeal,
                                  size: 50.sp,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: AppColors.primaryTeal,
                            size: 50.sp,
                          ),
                  ),

                  SizedBox(height: 16.h),

                  // Name
                  Text(
                    user?.displayName ?? 'User',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Email
                  Text(
                    user?.email ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Stats Section
              Obx(() {
                final userStats = leaderboardController.currentLeaderboard
                    .firstWhereOrNull((e) => e.isCurrentUser);

                return Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellowGreenLight,
                    borderRadius: BorderRadius.circular(20.r),
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
                        'Your Stats',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Iconsax.star,
                              label: 'Total Points',
                              value: '${userStats?.totalPoints ?? 0}',
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Iconsax.book,
                              label: 'Tests Completed',
                              value: '${userStats?.testsCompleted ?? 0}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.user,
                title: 'Edit Profile',
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement edit profile
                  Get.snackbar(
                    'Coming Soon',
                    'Edit profile feature coming soon',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: AppColors.info,
                    colorText: Colors.white,
                  );
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.setting,
                title: 'Settings',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.settings);
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.notification,
                title: 'Notifications',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.settings);
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.share,
                title: 'Share App',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _shareApp();
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.info_circle,
                title: 'About',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.about);
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.document,
                title: 'Privacy Policy',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.privacyPolicy);
                },
              ),

              SizedBox(height: 12.h),

              _buildMenuTile(
                icon: Iconsax.message,
                title: 'Contact Support',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ContactSupportDialog.show();
                },
              ),

              SizedBox(height: 24.h),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await authController.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.logout, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Logout',
                        style: AppTextStyles.label16.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out Quizzax - An amazing quiz app to test your knowledge and compete with others!\n\nDownload now and start learning!',
      subject: 'Quizzax - Quiz App',
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 32.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.accentYellowGreenLight,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 20.sp),
        ),
        title: Text(
          title,
          style: AppTextStyles.label16.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textLight,
          size: 16.sp,
        ),
        onTap: onTap,
      ),
    );
  }
}
