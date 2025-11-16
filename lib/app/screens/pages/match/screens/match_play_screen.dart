import 'dart:async';
import 'package:afn_test/app/app_widgets/app_colors.dart';
import 'package:afn_test/app/app_widgets/app_text_styles.dart';
import 'package:afn_test/app/controllers/match/match_controller.dart';
import 'package:afn_test/app/screens/pages/match/widgets/match_question_widget.dart';
import 'package:afn_test/app/screens/pages/match/widgets/match_timer_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'match_result_screen.dart';

/// Match Play Screen - 10 MCQs with 10 second timer
class MatchPlayScreen extends StatefulWidget {
  final String matchId;

  const MatchPlayScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchPlayScreen> createState() => _MatchPlayScreenState();
}

class _MatchPlayScreenState extends State<MatchPlayScreen> {
  Timer? _timer;
  Timer? _allPlayersAnsweredTimer;
  static const int QUESTION_DURATION_SECONDS = 10; // 10 seconds per question
  int _currentSeconds = QUESTION_DURATION_SECONDS;
  int _lastQuestionIndex = -1; // Track last question index
  bool _answerSubmitted = false;
  bool _isMovingToNext = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<MatchController>();
    // Ensure match listener is active
    controller.listenToMatch(widget.matchId);
    
    // Listen to match changes to detect question index changes
    ever(controller.currentMatch, (match) {
      if (match != null && mounted) {
        final currentIndex = match.currentQuestionIndex;
        if (currentIndex != _lastQuestionIndex && _lastQuestionIndex != -1) {
          // Question changed, restart timer
          _lastQuestionIndex = currentIndex;
          _initializeTimer();
          _checkAllPlayersAnswered();
        }
      }
    });
    
    _initializeTimer();
    _checkAllPlayersAnswered(); // Check if all players answered to move immediately
  }

  @override
  void dispose() {
    _timer?.cancel();
    _allPlayersAnsweredTimer?.cancel();
    super.dispose();
  }

  /// Initialize static countdown timer (no Firebase sync)
  void _initializeTimer() {
    // Cancel all existing timers
    _timer?.cancel();
    _allPlayersAnsweredTimer?.cancel();
    
    // Reset flags for new question
    _answerSubmitted = false;
    _isMovingToNext = false;
    
    final controller = Get.find<MatchController>();
    final match = controller.currentMatch.value;
    
    if (match == null) {
      print('⚠️ Match is null, cannot initialize timer');
      return;
    }
    
    // Update last question index
    final currentQuestionIndex = match.currentQuestionIndex;
    _lastQuestionIndex = currentQuestionIndex;
    
    print('🔄 Initializing static timer for question ${currentQuestionIndex + 1}...');
    
    // Reset timer to full duration
    if (mounted) {
      setState(() {
        _currentSeconds = QUESTION_DURATION_SECONDS;
      });
    }
    
    // Start static countdown timer
    _startLocalTimer();
  }
  
  /// Start static countdown timer (updates UI every second)
  void _startLocalTimer() {
    _timer?.cancel();
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted || _isMovingToNext) {
        timer.cancel();
        return;
      }
      
      final controller = Get.find<MatchController>();
      final match = controller.currentMatch.value;
      if (match == null) {
        timer.cancel();
        return;
      }
      
      // Check if question changed
      if (match.currentQuestionIndex != _lastQuestionIndex) {
        timer.cancel();
        _initializeTimer();
        _checkAllPlayersAnswered();
        return;
      }
      
      // Simple countdown
      if (mounted) {
        setState(() {
          if (_currentSeconds > 0) {
            _currentSeconds--;
          } else {
            // Timer reached 0 - immediately move to next question
            if (!_isMovingToNext) {
              _isMovingToNext = true;
              timer.cancel();
              _allPlayersAnsweredTimer?.cancel();
              
              print('⏰ Timer reached 0. Moving to next question...');
              
              // Submit answer if not submitted
              if (!_answerSubmitted) {
                final currentIndex = match.currentQuestionIndex;
                if (currentIndex >= 0 && currentIndex < match.questions.length) {
                  controller.submitAnswer(widget.matchId, currentIndex, -1).then((_) {
                    print('✅ Submitted empty answer (-1) for question ${currentIndex + 1}');
                  }).catchError((e) {
                    print('❌ Error submitting answer: $e');
                  });
                  _answerSubmitted = true;
                }
              }
              
              // Move to next question immediately
              Future.delayed(Duration(milliseconds: 200), () {
                if (mounted && _isMovingToNext) {
                  _moveToNextQuestion();
                }
              });
            }
          }
        });
      }
    });
  }
  
  /// Check if all players have answered
  void _checkAllPlayersAnswered() {
    _allPlayersAnsweredTimer?.cancel();
    
    final controller = Get.find<MatchController>();
    
    // Use a periodic check (every 1 second to avoid too frequent checks)
    _allPlayersAnsweredTimer = Timer.periodic(Duration(seconds: 1), (checkTimer) {
      if (_isMovingToNext || !mounted) {
        checkTimer.cancel();
        return;
      }
      
      final match = controller.currentMatch.value;
      if (match == null) {
        checkTimer.cancel();
        return;
      }
      
      // Check if question index changed (someone moved to next question)
      final currentQuestionIndex = match.currentQuestionIndex;
      if (currentQuestionIndex != _lastQuestionIndex) {
        // Question changed, restart timer for new question
        _lastQuestionIndex = currentQuestionIndex;
        checkTimer.cancel();
        _initializeTimer();
        _checkAllPlayersAnswered();
        return;
      }
      
      // Validate question index before accessing
      if (currentQuestionIndex < 0 || currentQuestionIndex >= match.questions.length) {
        print('⚠️ Invalid question index: $currentQuestionIndex (total: ${match.questions.length})');
        checkTimer.cancel();
        return;
      }
      
      final currentQuestion = match.questions[currentQuestionIndex];
      final questionId = currentQuestion.questionId;
      final maxPlayers = match.maxPlayers; // 2 or 4 players
      final answers = controller.allPlayersAnswers;
      
      // Count how many players have answered this question
      int answeredCount = 0;
      for (var player in match.players) {
        final playerAnswers = answers[player.userId] ?? {};
        if (playerAnswers.containsKey(questionId)) {
          answeredCount++;
        }
      }
      
      // If all players answered (based on maxPlayers), move immediately to next question
      if (answeredCount >= maxPlayers && !_isMovingToNext) {
        checkTimer.cancel();
        _isMovingToNext = true;
        _timer?.cancel(); // Stop timer since all answered
        _allPlayersAnsweredTimer?.cancel(); // Stop this check timer
        
        print('✅ All $maxPlayers players answered question ${currentQuestionIndex + 1}. Moving to next immediately...');
        
        // Move immediately (no wait needed since all answered)
        if (mounted) {
          _moveToNextQuestion();
        }
      }
    });
  }

  Future<void> _moveToNextQuestion() async {
    // Prevent multiple simultaneous calls
    if (!mounted) {
      print('⚠️ Widget disposed, cannot move to next question');
      _isMovingToNext = false;
      return;
    }
    
    // Double check to prevent duplicate calls (flag should already be set by caller)
    if (!_isMovingToNext) {
      _isMovingToNext = true;
    }
    
    // Cancel all timers immediately
    _timer?.cancel();
    _allPlayersAnsweredTimer?.cancel();
    
    final controller = Get.find<MatchController>();
    final match = controller.currentMatch.value;
    
    if (match == null) {
      print('⚠️ Match is null, cannot move to next question');
      _isMovingToNext = false;
      return;
    }
    
    // Validate match has questions
    if (match.questions.isEmpty) {
      print('⚠️ Match has no questions');
      _isMovingToNext = false;
      return;
    }
    
    // Validate current question index
    final currentIndex = match.currentQuestionIndex;
    final totalQuestions = match.questions.length;
    
    if (currentIndex < 0 || currentIndex >= totalQuestions) {
      print('⚠️ Invalid question index: $currentIndex (total questions: $totalQuestions)');
      _isMovingToNext = false;
      return;
    }
    
    if (currentIndex < totalQuestions - 1) {
      // Move to next question
      print('➡️ Moving from question ${currentIndex + 1} to ${currentIndex + 2} (total: $totalQuestions)...');
      controller.nextQuestion(widget.matchId).then((_) {
        print('✅ Successfully moved to next question in Firebase');
        // Wait a bit for Firebase to update, then reinitialize
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            // Reset all flags for new question
            _isMovingToNext = false;
            _answerSubmitted = false;
            
            // Force UI update by getting fresh match data
            final match = controller.currentMatch.value;
            if (match != null) {
              setState(() {
                // Force rebuild
              });
            }
            
            // Reinitialize timer for new question
            _initializeTimer();
            _checkAllPlayersAnswered(); // Re-enable check for new question
          }
        });
      }).catchError((e) {
        print('❌ Error moving to next question: $e');
        _isMovingToNext = false;
      });
    } else {
      // Match completed - navigate to results
      print('🏁 Match completed! All ${totalQuestions} questions answered. Navigating to results...');
      _isMovingToNext = false;
      
      // End match and calculate scores before navigating
      // Wait for scores to be calculated and saved
      await controller.endMatch(widget.matchId).then((_) {
        print('✅ Match ended, scores calculated. Navigating to results...');
        // Wait longer to ensure Firebase has updated and match data is refreshed
        Future.delayed(Duration(milliseconds: 1500), () {
          if (mounted) {
            // Ensure match data is refreshed before navigating
            controller.listenToMatch(widget.matchId);
            Get.off(() => MatchResultScreen(matchId: widget.matchId));
          }
        });
      }).catchError((e) {
        print('❌ Error ending match: $e');
        // Navigate anyway after a delay
        Future.delayed(Duration(milliseconds: 1500), () {
          if (mounted) {
            controller.listenToMatch(widget.matchId);
            Get.off(() => MatchResultScreen(matchId: widget.matchId));
          }
        });
      });
    }
  }

  void _handleAnswerSelected(int index) {
    if (_answerSubmitted) return;

    setState(() {
      _answerSubmitted = true;
    });

    // Don't cancel timer - let it run for other players
    // Timer will be handled by _checkAllPlayersAnswered

    final controller = Get.find<MatchController>();
    final match = controller.currentMatch.value;
    if (match != null) {
      final currentIndex = match.currentQuestionIndex;
      controller.submitAnswer(widget.matchId, currentIndex, index);
      
      // Don't move immediately - wait for all players or timeout
      // _checkAllPlayersAnswered will handle moving to next question
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Obx(() {
          final match = controller.currentMatch.value;
          if (match == null || match.questions.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
            );
          }

          final currentIndex = match.currentQuestionIndex;
          final question = match.questions[currentIndex];
          final selectedIndex = controller.playerAnswers[question.questionId];
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          
          // Calculate current score
          int currentScore = 0;
          if (currentUserId != null && match.scores.containsKey(currentUserId)) {
            currentScore = match.scores[currentUserId] ?? 0;
          } else {
            // Calculate from answers
            final playerAnswers = controller.allPlayersAnswers[currentUserId] ?? {};
            for (var entry in playerAnswers.entries) {
              final qId = entry.key;
              final selectedIdx = entry.value;
              try {
                final q = match.questions.firstWhere((q) => q.questionId == qId);
                if (selectedIdx == q.correctAnswerIndex && selectedIdx >= 0) {
                  currentScore++;
                }
              } catch (e) {
                // Question not found, skip
              }
            }
          }

          return Column(
            children: [
              // Header with Timer, Progress, and Score
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Progress and Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentIndex + 1}/10',
                          style: AppTextStyles.label16.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellowGreenLight,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Score: $currentScore/10',
                            style: AppTextStyles.label14.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        MatchTimerWidget(seconds: _currentSeconds),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    LinearProgressIndicator(
                      value: (currentIndex + 1) / 10,
                      backgroundColor: AppColors.accentYellowGreenLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),

              // Question and Options
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: MatchQuestionWidget(
                    question: question,
                    selectedIndex: selectedIndex,
                    onAnswerSelected: _handleAnswerSelected,
                    allPlayersAnswers: controller.allPlayersAnswers,
                    matchPlayers: match.players,
                    currentUserId: currentUserId,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

