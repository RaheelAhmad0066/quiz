import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/spinkit_loadder.dart';
import 'package:afn_test/app/controllers/quiz_controller.dart';
import 'package:afn_test/app/models/topic_model.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TopicsListScreen extends StatelessWidget {
  const TopicsListScreen({super.key});

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
          controller.selectedCategory.value.isNotEmpty
              ? '${controller.selectedCategory.value} Topics'
              : 'Topics',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primaryTeal,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoadingTopics.value) {
          return Center(
            child: SpinkitLoader(
              color: AppColors.primaryTeal,
            ),
          );
        }

        if (controller.topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.topic_outlined,
                  size: 64.sp,
                  color: AppColors.primaryTeal.withOpacity(0.5),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No topics available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please create topics in admin panel',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryTeal.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter topics that have questions
        // We'll use a FutureBuilder to get all topics with questions
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getTopicsWithQuestions(controller),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: SpinkitLoader(
                  color: AppColors.primaryTeal,
                ),
              );
            }

            final topicsWithQuestions = snapshot.data ?? [];
            
            if (topicsWithQuestions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.topic_outlined,
                      size: 64.sp,
                      color: AppColors.primaryTeal.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No topics with questions available',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please create questions for topics in admin panel',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryTeal.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: topicsWithQuestions.length,
              itemBuilder: (context, index) {
                final item = topicsWithQuestions[index];
                final topic = item['topic'] as TopicModel;
                final testCount = item['testCount'] as int;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _TopicListItem(
                          topic: topic,
                          testCount: testCount,
                          index: index,
                          onTap: () {
                            // Load tests for this topic and navigate to quiz progress
                            controller.loadTestsByTopic(topic.id).then((_) {
                              controller.selectedTopicId.value = topic.id;
                              Get.toNamed(AppRoutes.quizProgress);
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      }),
    );
  }

  // Helper method to get only topics that have questions
  Future<List<Map<String, dynamic>>> _getTopicsWithQuestions(
      QuizController controller) async {
    final topicsWithQuestions = <Map<String, dynamic>>[];
    
    for (var topic in controller.topics) {
      // Check if topic has questions
      final hasQuestions = await controller.topicHasQuestions(topic.id);
      if (hasQuestions) {
        final testCount = await controller.getTestCountForTopic(topic.id);
        topicsWithQuestions.add({
          'topic': topic,
          'testCount': testCount,
        });
      }
    }
    
    return topicsWithQuestions;
  }
}

class _TopicListItem extends StatefulWidget {
  final TopicModel topic;
  final int testCount;
  final int index;
  final VoidCallback onTap;

  const _TopicListItem({
    required this.topic,
    required this.testCount,
    required this.index,
    required this.onTap,
  });

  @override
  State<_TopicListItem> createState() => _TopicListItemState();
}

class _TopicListItemState extends State<_TopicListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get unique color for each topic based on index
  Color _getTopicColor() {
    final colors = [
      AppColors.primaryTeal,
      const Color(0xFF015055),
      const Color(0xFF017A7F),
      const Color(0xFF014A4F),
    ];
    return colors[widget.index % colors.length];
  }

  // Get unique background color
  Color _getBackgroundColor() {
    final backgrounds = [
      const Color(0xffEEF9C0),
      const Color(0xFFE2F299),
      const Color(0xFFE8F5A8),
      const Color(0xFFF0F9C8),
    ];
    return backgrounds[widget.index % backgrounds.length];
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = _getTopicColor();
    final backgroundColor = _getBackgroundColor();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.08),
                    blurRadius: _isPressed ? 10 : 6,
                    offset: Offset(0, _isPressed ? 3 : 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Leading Icon
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: topicColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Iconsax.document_text,
                        color: topicColor,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Topic Title - Expanded
                    Expanded(
                      child: Text(
                        widget.topic.name,
                        style: AppTextStyles.label16.copyWith(
                          color: topicColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Start Button with Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Container(
                        decoration: BoxDecoration(
                          color: topicColor,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: topicColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onTap,
                            borderRadius: BorderRadius.circular(10.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Start',
                                    style: AppTextStyles.label14.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Icon(
                                    Iconsax.arrow_right_3,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

