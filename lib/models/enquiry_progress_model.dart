class EnquiryProgress {
  final String id;
  final String enquiryId;
  final String status;
  final String? notes;
  final String? updatedBy;
  final DateTime createdAt;

  EnquiryProgress({
    required this.id,
    required this.enquiryId,
    required this.status,
    this.notes,
    this.updatedBy,
    required this.createdAt,
  });

  factory EnquiryProgress.fromJson(Map<String, dynamic> json) {
    return EnquiryProgress(
      id: json['id'] ?? '',
      enquiryId: json['enquiryId'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      updatedBy: json['updatedBy'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'notes': notes,
    };
  }
}
