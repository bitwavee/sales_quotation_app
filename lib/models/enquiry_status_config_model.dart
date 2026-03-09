class EnquiryStatusConfig {
  final String id;
  final String statusName;
  final String statusKey;
  final int displayOrder;
  final String? color;
  final bool isActive;
  final DateTime? createdAt;

  EnquiryStatusConfig({
    required this.id,
    required this.statusName,
    required this.statusKey,
    required this.displayOrder,
    this.color,
    required this.isActive,
    this.createdAt,
  });

  factory EnquiryStatusConfig.fromJson(Map<String, dynamic> json) {
    return EnquiryStatusConfig(
      id: json['id'] ?? '',
      statusName: json['statusName'] ?? '',
      statusKey: json['statusKey'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      color: json['color'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusName': statusName,
      'statusKey': statusKey,
      'displayOrder': displayOrder,
      'color': color,
      'isActive': isActive,
    };
  }
}
