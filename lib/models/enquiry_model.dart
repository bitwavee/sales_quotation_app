class Enquiry {
  final String id;
  final String enquiryNumber;
  final String customerName;
  final String? customerEmail;
  final String customerPhone;
  final String? customerAddress;
  final String? assignedStaffId;
  final String? assignedStaff;
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
    this.assignedStaff,
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
      enquiryNumber: json['enquiryNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'],
      assignedStaffId: json['assignedStaffId'],
      assignedStaff: json['assignedStaff'],
      status: json['status'] ?? 'INITIATED',
      notes: json['notes'],
      measurementsCount: json['measurementsCount'] ?? 0,
      quotationsCount: json['quotationsCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
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