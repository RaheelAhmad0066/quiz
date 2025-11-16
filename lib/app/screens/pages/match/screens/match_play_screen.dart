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
  StreamSubscription? _timerSubscription;
  int _currentSeconds = 30; // Changed to 30 seconds
  bool _answerSubmitted = false;
  bool _isMovingToNext = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<MatchController>();
    // Ensure match listener is active
    controller.listenToMatch(widget.matchId);
    _startTimer();
    _checkAllPlayersAnswered();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _allPlayersAnsweredTimer?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _answerSubmitted = false;
    _isMovingToNext = false;

    _timer?.cancel();
    _timerSubscription?.cancel();
    
    final controller = Get.find<MatchController>();
    
    // Use periodic timer to update UI every second based on Firebase timestamp
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final match = controller.currentMatch.value;
      
      if (match == null) {
        timer.cancel();
        return;
      }
      
      // Get question start time from Firebase (synchronized across all players)
      final matchRef = controller.databaseRef?.child('matches').child(widget.matchId);
      if (matchRef != null) {
        matchRef.child('currentQuestionStartTime').get().then((snapshot) {
          if (snapshot.exists && mounted) {
            final questionStartTime = snapshot.value as int?;
            if (questionStartTime != null) {
              // Calculate remaining time based on server timestamp (synchronized)
              final now = DateTime.now().millisecondsSinceEpoch;
              final elapsed = (now - questionStartTime) ~/ 1000; // seconds
              final remaining = 30 - elapsed;
              
              if (mounted) {
                setState(() {
                  _currentSeconds = remaining > 0 ? remaining : 0;
                });
                
                if (remaining <= 0) {
                  _timer?.cancel();
                  _handleTimeout();
                }
              }
            }
          }
        }).catchError((e) {
          // Fallback: use local countdown if server time not available
          if (mounted) {
            setState(() {
              if (_currentSeconds > 0) {
                _currentSeconds--;
              } else {
                timer.cancel();
                _handleTimeout();
              }
            });
          }
        });
      } else {
        // Fallback: use local countdown if Firebase not available
        if (mounted) {
          setState(() {
            if (_currentSeconds > 0) {
              _currentSeconds--;
            } else {
              timer.cancel();
              _handleTimeout();
            }
          });
        }
      }
    });
  }
  
  /// Check if all players have answered
  void _checkAllPlayersAnswered() {
    final controller = Get.find<MatchController>();
    
    // Use a periodic check instead of ever to avoid multiple listeners
    Timer.periodic(Duration(milliseconds: 500), (checkTimer) {
      if (_isMovingToNext || !mounted) {
        checkTimer.cancel();
        return;
      }
      
      final match = controller.currentMatch.value;
      if (match == null) {
        checkTimer.cancel();
        return;
      }
      
      final currentQuestion = match.questions[match.currentQuestionIndex];
      final questionId = currentQuestion.questionId;
      final totalPlayers = match.players.length;
      final answers = controller.allPlayersAnswers;
      
      // Count how many players have answered this question
      int answeredCount = 0;
      for (var player in match.players) {
        final playerAnswers = answers[player.userId] ?? {};
        if (playerAnswers.containsKey(questionId)) {
          answeredCount++;
        }
      }
      
      // If all players answered, wait 3 seconds then move to next
      if (answeredCount >= totalPlayers && !_isMovingToNext) {
        checkTimer.cancel();
        _allPlayersAnsweredTimer?.cancel();
        _isMovingToNext = true;
        
        print('✅ All $totalPlayers players answered question ${match.currentQuestionIndex + 1}. Waiting 3 seconds...');
        
        // Wait 3 seconds for any late answers
        _allPlayersAnsweredTimer = Timer(Duration(seconds: 3), () {
          if (mounted) {
            _moveToNextQuestion();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    if (!_answerSubmitted) {
      final controller = Get.find<MatchController>();
      final match = controller.currentMatch.value;
      if (match != null) {
        final currentIndex = match.currentQuestionIndex;
        // Submit no answer (or default)
        controller.submitAnswer(widget.matchId, currentIndex, -1);
      }
    }
    
    // After timeout, wait 3 seconds for other players, then move to next
    if (!_isMovingToNext) {
      _isMovingToNext = true;
      _allPlayersAnsweredTimer?.cancel();
      _allPlayersAnsweredTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          _moveToNextQuestion();
        }
      });
    }
  }

  void _moveToNextQuestion() {
    if (_isMovingToNext && mounted) {
      _isMovingToNext = false;
      _allPlayersAnsweredTimer?.cancel();
      
      final controller = Get.find<MatchController>();
      final match = controller.currentMatch.value;
      if (match != null) {
        if (match.currentQuestionIndex < match.questions.length - 1) {
          controller.nextQuestion(widget.matchId);
          _startTimer();
          _checkAllPlayersAnswered(); // Re-check for next question
        } else {
          // Match completed
          Get.off(() => MatchResultScreen(matchId: widget.matchId));
        }
      }
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

