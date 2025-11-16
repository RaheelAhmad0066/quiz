import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_icons.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/auth_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top spacing - Flexible
                  Flexible(
                    flex: isSmallScreen ? 1 : 2,
                    child: SizedBox.shrink(),
                  ),

                  // Logo/Icon
                  Container(
                    width: isSmallScreen ? 80.w : 100.w,
                    height: isSmallScreen ? 80.w : 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellowGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentYellowGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.book_1,
                      size: isSmallScreen ? 40.sp : 50.sp,
                      color: AppColors.primaryTeal,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20.h : 30.h),

                  // Welcome Text
                  Text(
                    'Welcome to\nQuizzax',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: isSmallScreen ? 28.sp : 32.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 8.h : 12.h),

                  Text(
                    'Sign in to continue your learning journey',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isSmallScreen ? 14.sp : 16.sp,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20.h : 30.h),

                  // Google Sign In Button
                  SocialAuthButton(
                    icon: AppIcons.google,
                    label: 'Continue with Google',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.signInWithGoogle();
                    },
                    backgroundColor: Colors.white,
                    textColor: AppColors.primaryTeal,
                    isSmallScreen: isSmallScreen,
                  ),

                  SizedBox(height: isSmallScreen ? 12.h : 16.h),

                  // Apple Sign In Button (iOS only)
                  if (GetPlatform.isIOS)
                    SocialAuthButton(
                      icon: AppIcons.apple,
                      label: 'Continue with Apple',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.signInWithApple();
                      },
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (GetPlatform.isIOS) SizedBox(height: isSmallScreen ? 12.h : 16.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'OR',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12.sp : 14.sp,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 16.h : 24.h),

                  // Email Login Button
                  _AuthButton(
                    label: 'Login with Email',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.toNamed(AppRoutes.login);
                    },
                    isPrimary: true,
                    isSmallScreen: isSmallScreen,
                  ),

                  SizedBox(height: isSmallScreen ? 12.h : 16.h),

                  // Sign Up Button
                  _AuthButton(
                    label: 'Create Account',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.toNamed(AppRoutes.signup);
                    },
                    isPrimary: false,
                    isSmallScreen: isSmallScreen,
                  ),

                  SizedBox(height: isSmallScreen ? 8.h : 12.h),

                  // Guest Mode Button
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.continueAsGuest();
                    },
                    child: Text(
                      'Continue as Guest',
                      style: AppTextStyles.label16.copyWith(
                        color: AppColors.accentYellowGreen,
                        decoration: TextDecoration.underline,
                        fontSize: isSmallScreen ? 14.sp : 16.sp,
                      ),
                    ),
                  ),

                  // Bottom spacing - Flexible
                  Flexible(
                    flex: isSmallScreen ? 1 : 2,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isSmallScreen;

  const _AuthButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12.h : 16.h,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.accentYellowGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppColors.accentYellowGreen,
                    width: 2,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.accentYellowGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label16.copyWith(
                color: isPrimary
                    ? AppColors.primaryTeal
                    : AppColors.accentYellowGreen,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 14.sp : 16.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
