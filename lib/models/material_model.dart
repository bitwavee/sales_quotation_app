class MaterialItem {
  final String id;
  final String name;
  final String? description;
  final String unit;
  final double baseCost;
  final bool isActive;
  final DateTime? createdAt;

  MaterialItem({
    required this.id,
    required this.name,
    this.description,
    required this.unit,
    required this.baseCost,
    required this.isActive,
    this.createdAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      unit: json['unit'] ?? '',
      baseCost: (json['baseCost'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'unit': unit,
      'baseCost': baseCost,
    };
  }
}
