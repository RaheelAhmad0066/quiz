class TestModel {
  final String id;
  final String topicId;
  final String name;
  final int questionCount;
  final DateTime createdAt;

  TestModel({
    required this.id,
    required this.topicId,
    required this.name,
    this.questionCount = 0,
    required this.createdAt,
  });

  factory TestModel.fromJson(Map<String, dynamic> json, String id) {
    return TestModel(
      id: id,
      topicId: json['topicId'] ?? '',
      name: json['name'] ?? '',
      questionCount: json['questionCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'name': name,
      'questionCount': questionCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

