import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/app_widgets/theme/app_themes.dart';
import 'package:afn_test/app/screens/dashbord/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.find();
  final List<IconData> listOfIcons = [
    Iconsax.home,
    Iconsax.people, // Match instead of favorite
    Iconsax.ranking, // Leaderboard icon
    Iconsax.user,
  ];

  final List<String> listOfStrings = [
    'Home',
    'Match',
    'Leaderboard',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    double displayWidth = MediaQuery.of(context).size.width;

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: controller.pages[controller.currentIndex.value],

        bottomNavigationBar: Container(
          margin: EdgeInsets.all(displayWidth * .05),
          height: displayWidth * .155,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            borderRadius: BorderRadius.circular(50),
          ),
          child: ListView.builder(
            itemCount: listOfIcons.length,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: displayWidth * .02),
            itemBuilder: (context, index) => InkWell(
              onTap: () {
                controller.changePage(index);
                HapticFeedback.lightImpact();
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastLinearToSlowEaseIn,
                    width: index == controller.currentIndex.value
                        ? displayWidth * .32
                        : displayWidth * .18,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.fastLinearToSlowEaseIn,
                      height: index == controller.currentIndex.value
                          ? displayWidth * .12
                          : 0,
                      width: index == controller.currentIndex.value
                          ? displayWidth * .32
                          : 0,
                      decoration: BoxDecoration(
                        color: index == controller.currentIndex.value
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastLinearToSlowEaseIn,
                    width: index == controller.currentIndex.value
                        ? displayWidth * .31
                        : displayWidth * .18,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.fastLinearToSlowEaseIn,
                              width: index == controller.currentIndex.value
                                  ? displayWidth * .13
                                  : 0,
                            ),
                            Flexible(
                              child: AnimatedOpacity(
                                opacity:
                                    index == controller.currentIndex.value ? 1 : 0,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.fastLinearToSlowEaseIn,
                                child: Text(
                                  index == controller.currentIndex.value
                                      ? listOfStrings[index]
                                      : '',
                                  style: AppTextStyles.label16.copyWith(
                                    color: AppTheme.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.fastLinearToSlowEaseIn,
                              width: index == controller.currentIndex.value
                                  ? displayWidth * .03
                                  : 20,
                            ),
                            Icon(
                              listOfIcons[index],
                              size: displayWidth * .070,
                              color: index == controller.currentIndex.value
                                  ? AppTheme.primaryTeal
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
