class PromotionModel {
  PromotionModel({required this.id, required this.name, required this.type, required this.isActive, this.description, this.priority = 0});
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final String? description;
  final int priority;

  factory PromotionModel.fromJson(Map<String, dynamic> j) => PromotionModel(
    id: '${j['id']}',
    name: (j['name'] ?? '').toString(),
    type: (j['type'] ?? '').toString(),
    isActive: j['is_active'] == true || j['isActive'] == true,
    description: j['description']?.toString(),
    priority: (j['priority'] as num?)?.toInt() ?? 0,
  );
}
