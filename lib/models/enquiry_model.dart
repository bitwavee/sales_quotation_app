class Enquiry {
  final String id;
  final String enquiryNumber;
  final String customerName;
  final String? customerEmail;
  final String customerPhone;
  final String? customerAddress;
  final String? assignedStaffId;
  final String status;
  final String? notes;
  final int measurementsCount;
  final int quotationsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Enquiry({
    required this.id,
    required this.enquiryNumber,
    required this.customerName,
    this.customerEmail,
    required this.customerPhone,
    this.customerAddress,
    this.assignedStaffId,
    required this.status,
    this.notes,
    this.measurementsCount = 0,
    this.quotationsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id'] ?? '',
      enquiryNumber: json['enquiryNumber'] ?? json['enquiry_number'] ?? '',
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerEmail: json['customerEmail'] ?? json['customer_email'],
      customerPhone: json['customerPhone'] ?? json['customer_phone'] ?? '',
      customerAddress: json['customerAddress'] ?? json['customer_address'],
      assignedStaffId: json['assignedStaffId'] ?? json['assigned_staff_id'],
      status: json['status'] ?? 'INITIATED',
      notes: json['notes'],
      measurementsCount: json['measurementsCount'] ?? json['measurements_count'] ?? 0,
      quotationsCount: json['quotationsCount'] ?? json['quotations_count'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'notes': notes,
    };
  }
}