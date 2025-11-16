class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) {
    return CategoryModel(
      id: id,
      name: json['name'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}

