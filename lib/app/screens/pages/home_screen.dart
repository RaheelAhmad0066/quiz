import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_icons.dart';
import 'package:afn_test/app/app_widgets/app_toast.dart';
import 'package:afn_test/app/app_widgets/custom_textfield.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/spinkit_loadder.dart';
import 'package:afn_test/app/controllers/quiz_controller.dart';
import 'package:afn_test/app/controllers/auth_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuizController controller = Get.put(QuizController());
  final AuthController authController = Get.put(AuthController());
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Map category names to icons
  String? getCategoryIcon(String categoryName) {
    final categoryLower = categoryName.toLowerCase();
    if (categoryLower.contains('math') || categoryLower.contains('geometry')) {
      return AppIcons.math;
    } else if (categoryLower.contains('physics')) {
      return AppIcons.atom;
    } else if (categoryLower.contains('chemistry')) {
      return AppIcons.chemistry;
    } else if (categoryLower.contains('biology')) {
      return AppIcons.bio;
    } else if (categoryLower.contains('english')) {
      return AppIcons.english;
    } else if (categoryLower.contains('ai') || categoryLower.contains('artificial')) {
      return AppIcons.ai;
    } else if (categoryLower.contains('intelligence')) {
      return AppIcons.intelligence;
    } else if (categoryLower.contains('geography') || categoryLower.contains('geo')) {
      return AppIcons.geography;
    }
    return AppIcons.math; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Text(
                  'Hello',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
                ),
                Obx(() {
                  final user = authController.user.value;
                  return Text(
                    user?.displayName ?? 'Guest',
                    style: AppTextStyles.label16.copyWith(color: Colors.black),
                  );
                }),
                SizedBox(height: 16.h),
                Text(
                  'What Subject Do You Want To Improve today?',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                CustomTextfield(
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: AppColors.primaryTeal,
                    size: 20.sp,
                  ),
                  controller: searchController,
                  hintText: 'Search for a subject',
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: 24.h),
                // Grid View for Categories from Firebase
                Obx(() {
                  // Access reactive variables directly to ensure GetX can track them
                  final isLoading = controller.isLoadingCategories.value;
                  final categoriesList = controller.categories;
                  final query = searchQuery.value;
                  
                  if (isLoading) {
                    return SizedBox(
                      height: 400.h,
                      child: Center(
                        child: SpinkitLoader(),
                      ),
                    );
                  }

                  // Filter categories based on search query
                  final filteredCategories = categoriesList
                      .where((cat) => cat.name.toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();

                  if (filteredCategories.isEmpty) {
                    return SizedBox(
                      height: 400.h,
                      child: Center(
                        child: Text(
                          query.isEmpty
                              ? 'No categories found'
                              : 'No categories match "$query"',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    );
                  }

                  // Calculate grid height based on item count
                  final itemCount = filteredCategories.length;
                  final rowCount = (itemCount / 2).ceil();
                  final screenWidth = MediaQuery.of(context).size.width;
                  final cardWidth = (screenWidth - 24.w - 16.w) / 2; // Screen width - padding - spacing
                  final cardHeight = cardWidth / 0.85; // Based on aspect ratio
                  final gridHeight = (rowCount * cardHeight) + ((rowCount - 1) * 16.h);

                  return SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling, parent scrolls
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.85, // Adjust card height
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return _SubjectCard(
                          name: category.name,
                          iconPath: getCategoryIcon(category.name),
                          index: index,
                          categoryName: category.name, // Use category name instead of ID
                        );
                      },
                    ),
                  );
                }),
                
                // Bottom padding for navigation bar
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Subject Card Widget with Animation
class _SubjectCard extends StatefulWidget {
  final String name;
  final String? iconPath;
  final int index;
  final String categoryName; // Changed to use category name instead of ID

  const _SubjectCard({
    required this.name,
    this.iconPath,
    required this.index,
    required this.categoryName, // Changed to use category name instead of ID
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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

  @override
  Widget build(BuildContext context) {
    // Pehla card (index 0) ka color primaryTeal, baki sab ka yellow
    final cardColor = widget.index == 0
        ? AppColors.primaryTeal
        : const Color(0xffEEF9C0);
    
    // First card ke liye text white, baki ke liye primaryTeal
    final textColor = widget.index == 0
        ? Colors.white
        : AppColors.primaryTeal;
    
    // First card ke liye image yellow, baki ke liye primaryTeal
    final imageColor = widget.index == 0
        ? const Color(0xffEEF9C0)
        : AppColors.primaryTeal;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        // Navigate to topics list screen
        final quizController = Get.isRegistered<QuizController>()
            ? Get.find<QuizController>()
            : Get.put(QuizController());
        
        // Use category name directly (topics use category name, not ID)
        quizController.loadTopicsByCategory(widget.categoryName).then((_) {
          if (quizController.topics.isNotEmpty) {
            Get.toNamed(AppRoutes.topicsList);
          } else {
            AppToast.showCustomToast(
              'No Topics',
              'No topics found for ${widget.categoryName}',
              type: ToastType.info,
            );
          }
        }).catchError((error) {
          AppToast.showCustomToast(
            'Error',
            'Failed to load topics: ${error.toString()}',
            type: ToastType.error,
          );
        });
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isPressed ? 0.15 : 0.1),
                    blurRadius: _isPressed ? 15 : 10,
                    offset: Offset(0, _isPressed ? 6.h : 4.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with conditional color filter
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: widget.iconPath != null
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              imageColor,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              widget.iconPath!,
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              color: imageColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.book_1,
                              size: 30.sp,
                              color: imageColor,
                            ),
                          ),
                  ),
                  SizedBox(height: 12.h),
                  // Subject Name with conditional color
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTextStyles.label16.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
