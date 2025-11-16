import 'package:collection/collection.dart';

/// Match Model
class MatchModel {
  final String matchId;
  final String createdBy;
  final DateTime createdAt;
  final MatchStatus status;
  final List<MatchPlayer> players;
  final List<MatchQuestion> questions;
  final int currentQuestionIndex;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, int> scores; // userId -> score
  final String? categoryId;
  final String? topicId;
  final bool isLocked; // Locked when 4 players join
  final bool isClosed; // Closed by creator

  MatchModel({
    required this.matchId,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    required this.players,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.startedAt,
    this.endedAt,
    Map<String, int>? scores,
    this.categoryId,
    this.topicId,
    this.isLocked = false,
    this.isClosed = false,
  }) : scores = scores ?? {};

  factory MatchModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return MatchModel(
      matchId: id,
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      status: MatchStatus.fromString(json['status']?.toString() ?? 'waiting'),
      players: (json['players'] as List<dynamic>?)
              ?.map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => MatchQuestion.fromJson(Map<String, dynamic>.from(q)))
              .toList() ??
          [],
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endedAt'] as int)
          : null,
      scores: json['scores'] != null
          ? Map<String, int>.from(json['scores'])
          : {},
      categoryId: json['categoryId']?.toString(),
      topicId: json['topicId']?.toString(),
      isLocked: json['isLocked'] ?? false,
      isClosed: json['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.toString(),
      'players': players.map((p) => p.toJson()).toList(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentQuestionIndex': currentQuestionIndex,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'scores': scores,
      'categoryId': categoryId,
      'topicId': topicId,
      'isLocked': isLocked,
      'isClosed': isClosed,
    };
  }

  bool get isFull => players.length >= 4;
  bool get canStart => players.length == 4 && status == MatchStatus.waiting;
  
  // Get winner from scores
  String? get winnerId {
    if (scores.isEmpty) return null;
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedScores.first.key;
  }
  
  String? get winnerName {
    final winner = winnerId;
    if (winner == null) return null;
    return players.firstWhereOrNull((p) => p.userId == winner)?.userName;
  }
}

/// Match Player Model
class MatchPlayer {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userEmail;
  final bool isReady;
  final int score;
  final DateTime? joinedAt;

  MatchPlayer({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userEmail,
    this.isReady = false,
    this.score = 0,
    this.joinedAt,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Unknown',
      userAvatar: json['userAvatar']?.toString(),
      userEmail: json['userEmail']?.toString() ?? '',
      isReady: json['isReady'] ?? false,
      score: json['score'] ?? 0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userEmail': userEmail,
      'isReady': isReady,
      'score': score,
      'joinedAt': joinedAt?.millisecondsSinceEpoch,
    };
  }
}

/// Match Question Model
class MatchQuestion {
  final String questionId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  MatchQuestion({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory MatchQuestion.fromJson(Map<String, dynamic> json) {
    return MatchQuestion(
      questionId: json['questionId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

/// Match Status Enum
enum MatchStatus {
  waiting,
  starting,
  inProgress,
  completed,
  cancelled;

  static MatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'waiting':
        return MatchStatus.waiting;
      case 'starting':
        return MatchStatus.starting;
      case 'inprogress':
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.waiting;
    }
  }

  @override
  String toString() {
    switch (this) {
      case MatchStatus.waiting:
        return 'waiting';
      case MatchStatus.starting:
        return 'starting';
      case MatchStatus.inProgress:
        return 'inProgress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }
}

