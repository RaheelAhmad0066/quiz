import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/quiz_controller.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class MCQQuizScreen extends StatelessWidget {
  const MCQQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();
    final ttsController = Get.put(TTSController());
    final audioController = Get.put(AudioController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light background
      body: SafeArea(
        child: Obx(() {
        final currentQuestion = controller.getCurrentQuestion();
        if (currentQuestion == null) {
          return Center(
            child: Text(
              'No questions available',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryTeal,
              ),
            ),
          );
        }

        final questionIndex = controller.currentQuestionIndex.value;
        final selectedAnswer = controller.getSelectedAnswer(questionIndex);
        final isAnswered = controller.isQuestionAnswered(questionIndex);
        final isCorrect = isAnswered && controller.isAnswerCorrect(questionIndex);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // White Container with Shadow for Question and Options
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      
                      ),
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Number
                          Text(
                            'Question ${questionIndex + 1}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Question Text with Speaker Icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  currentQuestion.question,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Obx(() => GestureDetector(
                                    onTap: () => ttsController.speak(currentQuestion.question),
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        ttsController.isSpeaking.value
                                            ? Icons.volume_up
                                            : Icons.volume_up_outlined,
                                        color: AppColors.primaryTeal,
                                        size: 20.sp,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Options with Animation
                          ...currentQuestion.options.asMap().entries.map((entry) {
                            final optionIndex = entry.key;
                            final option = entry.value;
                            final isSelected = selectedAnswer == optionIndex;
                            final isCorrectOption = optionIndex == currentQuestion.correctAnswerIndex;

                            Color optionColor;
                            Color textColor;
                            Color borderColor;
                            bool showCheckIcon = false;

                            if (isAnswered) {
                              if (isCorrectOption) {
                                // Correct answer - always show in green
                                optionColor = const Color(0xffEEF9C0);
                                textColor = AppColors.primaryTeal;
                                borderColor = Colors.transparent;
                                showCheckIcon = true;
                              } else if (isSelected && !isCorrect) {
                                // Wrong selected answer - red
                                optionColor = Colors.red.shade50;
                                textColor = Colors.red.shade700;
                                borderColor = Colors.red.shade300;
                              } else {
                                // Other options - neutral
                                optionColor = Colors.white;
                                textColor = AppColors.primaryTeal;
                                borderColor = Colors.grey.shade300;
                              }
                            } else {
                              // Not answered yet
                              optionColor = Colors.white;
                              textColor = AppColors.primaryTeal;
                              borderColor = Colors.grey.shade300;
                            }

                            return AnimatedContainer(
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: GestureDetector(
                                onTap: () {
                                  if (!isAnswered) {
                                    // Play sound effect first
                                    if (optionIndex == currentQuestion.correctAnswerIndex) {
                                      audioController.playCorrectSound();
                                    } else {
                                      audioController.playWrongSound();
                                    }
                                    // Then select answer (with slight delay for smooth animation)
                                    Future.delayed(Duration(milliseconds: 100), () {
                                      controller.selectAnswer(questionIndex, optionIndex);
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                                  decoration: BoxDecoration(
                                    color: optionColor,
                                    borderRadius: BorderRadius.circular(32.r),
                                    border: Border.all(
                                      color: borderColor,
                                      width: isAnswered && (isCorrectOption || isSelected) ? 2 : 1,
                                    ),
                                    boxShadow: isAnswered && isCorrectOption
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xffEEF9C0).withOpacity(0.5),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      
                                      if (showCheckIcon) SizedBox(width: 8.w),
                                      Flexible(
                                        child: Text(
                                          option,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Explanation Section with Light Blue Background
                    if (isAnswered && currentQuestion.explanation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Explanation:',
                            style: AppTextStyles.label16.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildExplanation(currentQuestion.explanation!),
                          SizedBox(height: 16.h),
                          // Answer Validation Message
                          AnimatedOpacity(
                            opacity: isAnswered ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? AppColors.primaryTeal : Colors.red,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  isCorrect
                                      ? 'Your answer is correct.'
                                      : 'Your answer is incorrect.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isCorrect
                                        ? AppColors.primaryTeal
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Navigation Buttons - Integrated in body with smooth animation
            SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip Button (Outline) - More rounded
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 160.w,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          controller.nextQuestion();
                        },
                        borderRadius: BorderRadius.circular(30.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: AppColors.primaryTeal,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Save & Next Button (Filled) - More rounded
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 160.w,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isAnswered
                            ? () async {
                                if (questionIndex < controller.getTotalQuestions() - 1) {
                                  controller.nextQuestion();
                                } else {
                                  // Submit quiz results and show score screen
                                  final results = await controller.submitQuizResults();
                                  Get.offNamed(
                                    AppRoutes.score,
                                    arguments: results,
                                  );
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(30.r),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? AppColors.primaryTeal
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: isAnswered
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryTeal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              questionIndex < controller.getTotalQuestions() - 1
                                  ? 'Save & Next'
                                  : 'Finish',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: isAnswered ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        }),
      ),
    );
  }

  // Helper method to build explanation with steps
  Widget _buildExplanation(String explanation) {
    final lines = explanation.split('\n');
    final hasSteps = lines.any((line) => line.trim().toLowerCase().startsWith('step:'));

    if (hasSteps) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          if (line.trim().isEmpty) return SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              line.trim(),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        explanation,
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.primaryTeal,
          fontWeight: FontWeight.w400,
        ),
      );
    }
  }
}

// TTS Controller using GetX
class TTSController extends GetxController {
  FlutterTts flutterTts = FlutterTts();
  final isSpeaking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });
  }

  Future<void> speak(String text) async {
    if (isSpeaking.value) {
      await flutterTts.stop();
      isSpeaking.value = false;
    } else {
      isSpeaking.value = true;
      await flutterTts.speak(text);
    }
  }

  @override
  void onClose() {
    flutterTts.stop();
    super.onClose();
  }
}

// Audio Controller using GetX
class AudioController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    // Set audio player mode
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> playCorrectSound() async {
    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();
      
      // Try different path formats for asset loading
      final paths = ['assets/correct.mp3', 'correct.mp3'];
      bool played = false;
      
      for (final path in paths) {
        try {
          await _audioPlayer.play(AssetSource(path));
          played = true;
          break;
        } catch (e) {
          // Try next path
          continue;
        }
      }
      
      if (!played) {
        print('Could not load correct.mp3 from any path');
      }
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  Future<void> playWrongSound() async {
    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();
      
      // Try different path formats for asset loading
      final paths = ['assets/wrong.mp3', 'wrong.mp3'];
      bool played = false;
      
      for (final path in paths) {
        try {
          await _audioPlayer.play(AssetSource(path));
          played = true;
          break;
        } catch (e) {
          // Try next path
          continue;
        }
      }
      
      if (!played) {
        print('Could not load wrong.mp3 from any path');
      }
    } catch (e) {
      print('Error playing wrong sound: $e');
    }
  }

  @override
  void onClose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.onClose();
  }
}
