import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/custom_button.dart';
import 'package:afn_test/app/app_widgets/custom_textfield.dart';
import 'package:afn_test/app/controllers/signup_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
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
                      flex: isSmallScreen ? 0 : 1,
                      child: SizedBox.shrink(),
                    ),

                    // Title
                    Text(
                      'Create Account',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: isSmallScreen ? 28.sp : 32.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 4.h : 8.h),

                    Text(
                      'Sign up to get started',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 14.sp : 16.sp,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 10.h : 20.h),

                    // Name Field
                    CustomTextfield(
                      controller: controller.nameController,
                      hintText: 'Full Name',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icon(
                        Iconsax.user,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                      validator: controller.validateName,
                    ),

                    SizedBox(height: isSmallScreen ? 8.h : 12.h),

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

                    SizedBox(height: isSmallScreen ? 8.h : 12.h),

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

                    SizedBox(height: isSmallScreen ? 8.h : 12.h),

                    // Confirm Password Field
                    Obx(() => CustomTextfield(
                      controller: controller.confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: controller.obscureConfirmPassword.value,
                      prefixIcon: Icon(
                        Iconsax.lock_1,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                      suffixIcon: InkWell(
                        onTap: controller.toggleConfirmPasswordVisibility,
                        child: Icon(
                          controller.obscureConfirmPassword.value
                              ? Iconsax.eye_slash
                              : Iconsax.eye,
                          color: AppColors.primaryTeal,
                          size: 20.sp,
                        ),
                      ),
                      validator: (value) => controller.validateConfirmPassword(
                        value,
                        controller.passwordController.text,
                      ),
                    )),

                    SizedBox(height: isSmallScreen ? 20.h : 32.h),

                    // Sign Up Button
                    Obx(() => CustomButton(
                      text: 'Sign Up',
                      onPressed: controller.handleSignup,
                      backgroundColor: AppColors.accentYellowGreen,
                      textColor: AppColors.textPrimary,
                      isLoading: controller.authController.isLoading.value,
                    )),

                    SizedBox(height: isSmallScreen ? 16.h : 24.h),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12.sp : 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.login);
                          },
                          child: Text(
                            'Login',
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
                      flex: isSmallScreen ? 0 : 1,
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
