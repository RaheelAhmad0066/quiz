class TopicModel {
  final String id;
  final String name;
  final String category;
  final DateTime createdAt;
  final int testCount;

  TopicModel({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    this.testCount = 0,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json, String id) {
    return TopicModel(
      id: id,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      testCount: json['testCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'testCount': testCount,
    };
  }
}

