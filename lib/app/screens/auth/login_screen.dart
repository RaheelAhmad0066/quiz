import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_icons.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/custom_button.dart';
import 'package:afn_test/app/app_widgets/custom_textfield.dart';
import 'package:afn_test/app/controllers/auth_controller.dart';
import 'package:afn_test/app/controllers/login_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final authController = Get.find<AuthController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top spacing
                    Flexible(
                      flex: isSmallScreen ? 1 : 2,
                      child: SizedBox.shrink(),
                    ),

                    // Title
                    Text(
                      'Welcome Back!',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: isSmallScreen ? 28.sp : 32.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 4.h : 8.h),

                    Text(
                      'Login to continue',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 14.sp : 16.sp,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 24.h : 40.h),

                    // Email Field
                    CustomTextfield(
                      controller: controller.emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(
                        Iconsax.sms,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                      validator: controller.validateEmail,
                    ),

                    SizedBox(height: isSmallScreen ? 16.h : 20.h),

                    // Password Field
                    Obx(() => CustomTextfield(
                      controller: controller.passwordController,
                      hintText: 'Password',
                      obscureText: controller.obscurePassword.value,
                      prefixIcon: Icon(
                        Iconsax.lock,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                      suffixIcon: InkWell(
                        onTap: controller.togglePasswordVisibility,
                        child: Icon(
                          controller.obscurePassword.value
                              ? Iconsax.eye_slash
                              : Iconsax.eye,
                          color: AppColors.primaryTeal,
                          size: 20.sp,
                        ),
                      ),
                      validator: controller.validatePassword,
                    )),



                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.label14.copyWith(
                            color: AppColors.accentYellowGreen,
                            fontSize: isSmallScreen ? 12.sp : 14.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20.h : 32.h),

                    // Login Button
                    Obx(() => CustomButton(
                      text: 'Login',
                      onPressed: controller.handleLogin,
                      backgroundColor: AppColors.accentYellowGreen,
                      textColor: AppColors.textPrimary,
                      isLoading: controller.authController.isLoading.value,
                    )),

                    SizedBox(height: isSmallScreen ? 16.h : 24.h),

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

                    // Google Sign In Button
                    SocialAuthButton(
                      icon: AppIcons.google,
                      label: 'Continue with Google',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        authController.signInWithGoogle();
                      },
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryTeal,
                      isSmallScreen: isSmallScreen,
                      isGoogle: true,
                    ),

                    if (GetPlatform.isIOS) ...[
                      SizedBox(height: isSmallScreen ? 12.h : 16.h),
                      // Apple Sign In Button (iOS only)
                      SocialAuthButton(
                        icon: AppIcons.apple,
                        label: 'Continue with Apple',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          authController.signInWithApple();
                        },
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],

                    SizedBox(height: isSmallScreen ? 16.h : 24.h),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12.sp : 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.signup);
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTextStyles.label14.copyWith(
                              color: AppColors.accentYellowGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom spacing
                    Flexible(
                      flex: isSmallScreen ? 1 : 2,
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Social Auth Button Widget
class SocialAuthButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final bool isSmallScreen;
  final bool isGoogle;

  const SocialAuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.isSmallScreen = false,
    this.isGoogle = false,
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
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          
              
                Image.asset(icon, width: isSmallScreen ? 20.w : 24.w, height: isSmallScreen ? 20.w : 24.w),
              SizedBox(width: 12.w),
              Text(
                label,
                style: AppTextStyles.label16.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14.sp : 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
