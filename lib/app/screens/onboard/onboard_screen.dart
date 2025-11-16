import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/constant/keys.dart';
import 'package:afn_test/app/app_widgets/theme/app_themes.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/screens/onboard/widgets/box_patteren_widgets.dart';
import 'package:afn_test/app/services/prefferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation
    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top spacing
            SizedBox(height: 40.h),

            // Box Pattern Graphic - Center
            Center(
              child: BoxPatternGraphic(
                size: 250.w,
                lineColor: AppTheme.accentYellowGreen,
              ),
            ),

            SizedBox(height: 32.h),
            
            // Content with padding on column
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.headlineLarge,
                          children: [
                            const TextSpan(text: 'Think '),
                            TextSpan(
                              text: 'Outside',
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.accentYellowGreen,
                              ),
                            ),
                            const TextSpan(text: '\n'),
                            TextSpan(
                              text: 'the Box',
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.accentYellowGreen,
                              ),
                            ),
                            const TextSpan(text: ' with \n'),
                            const TextSpan(text: 'Quizzax'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Description with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        'Take your learning to the next level with our interactive and personalised quizzes.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.backgroundColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Continue Button - Right aligned
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: () async {
                        // Mark onboarding as completed
                        if (Get.isRegistered<Preferences>()) {
                          final prefs = Get.find<Preferences>();
                          await prefs.setBool(Keys.onboardingCompleted, true);
                        }
                        Get.toNamed(AppRoutes.auth);
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: AppTextStyles.label18.copyWith(
                                color: AppColors.accentYellowGreen,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Iconsax.login_1,
                              color: AppColors.accentYellowGreen,
                              size: 24.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom spacing
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
