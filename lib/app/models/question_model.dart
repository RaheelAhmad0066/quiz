class QuestionModel {
  final String id;
  final String testId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuestionModel({
    required this.id,
    required this.testId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json, String id) {
    return QuestionModel(
      id: id,
      testId: json['testId'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

