import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/app_toast.dart';
import 'package:afn_test/app/app_widgets/spinkit_loadder.dart';
import 'package:afn_test/app/controllers/quiz_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class QuizProgressScreen extends StatelessWidget {
  const QuizProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find with fallback to Get.put if not registered
    final controller = Get.isRegistered<QuizController>()
        ? Get.find<QuizController>()
        : Get.put(QuizController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryTeal),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Quiz Progress',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primaryTeal,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoadingTests.value) {
          return Center(
            child: SpinkitLoader(
              color: AppColors.primaryTeal,
            ),
          );
        }

        if (controller.tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64.sp,
                  color: AppColors.primaryTeal.withOpacity(0.5),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No tests available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please create tests in admin panel',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryTeal.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tests Grid - Show numbered boxes
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 5 columns
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: controller.tests.length,
                      itemBuilder: (context, index) {
                        final test = controller.tests[index];
                        final isSelected = controller.selectedTestId.value == test.id;

                        // Determine status
                        String status = 'unsolved';
                        if (isSelected) {
                          status = 'current';
                        } else if (test.questionCount > 0) {
                          // If test has questions, consider it solved
                          status = 'solved';
                        }

                        return _TestBox(
                          testNumber: index + 1,
                          status: status,
                          onTap: () {
                            controller.selectedTestId.value = test.id;
                            controller.loadQuestionsByTest(test.id).then((_) {
                              if (controller.questions.isNotEmpty) {
                                Get.toNamed(AppRoutes.mcqQuiz);
                              } else {
                                AppToast.showCustomToast(
                                  'No Questions',
                                  'This test has no questions yet',
                                  type: ToastType.info,
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                    // Legend at bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(
                          color: const Color(0xffEEF9C0), // Light green/lime
                          label: 'Solved',
                          hasBorder: false,
                        ),
                        SizedBox(width: 16.w),
                        _LegendItem(
                          color: AppColors.primaryTeal, // Dark teal
                          label: 'Current Question',
                          hasBorder: false,
                        ),
                        SizedBox(width: 16.w),
                        _LegendItem(
                          color: Colors.white,
                          label: 'Unsolved',
                          hasBorder: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TestBox extends StatelessWidget {
  final int testNumber;
  final String status; // 'solved', 'current', 'unsolved'
  final VoidCallback onTap;

  const _TestBox({
    required this.testNumber,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color boxColor;
    Color textColor;
    Border? border;

    switch (status) {
      case 'solved':
        boxColor = const Color(0xffEEF9C0); // Light green/lime
        textColor = AppColors.primaryTeal; // Dark teal for numbers
        border = null;
        break;
      case 'current':
        boxColor = AppColors.primaryTeal; // Dark teal
        textColor = Colors.white; // White numbers
        border = null;
        break;
      default: // unsolved
        boxColor = Colors.white;
        textColor = AppColors.primaryTeal; // Dark teal for numbers
        border = Border.all(
          color: Colors.grey.shade300,
          width: 1,
        );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(8.r),
          border: border,
        ),
        child: Center(
          child: Text(
            '$testNumber',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasBorder;

  const _LegendItem({
    required this.color,
    required this.label,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
            border: hasBorder
                ? Border.all(color: Colors.grey.shade300, width: 1)
                : null,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

