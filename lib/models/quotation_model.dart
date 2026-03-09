class QuotationItem {
  final String? id;
  final String? materialName;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  final String? notes;

  QuotationItem({
    this.id,
    this.materialName,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.notes,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id'],
      materialName: json['materialName'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitCost: (json['unitCost'] ?? 0).toDouble(),
      lineTotal: (json['lineTotal'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}

class Quotation {
  final String id;
  final String enquiryId;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final String status;
  final String? pdfPath;
  final List<QuotationItem> items;
  final DateTime? sentAt;
  final DateTime createdAt;

  Quotation({
    required this.id,
    required this.enquiryId,
    required this.quotationNumber,
    this.quotationDate,
    this.validUntil,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.status,
    this.pdfPath,
    required this.items,
    this.sentAt,
    required this.createdAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    List<QuotationItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((e) => QuotationItem.fromJson(e))
          .toList();
    }

    return Quotation(
      id: json['id'] ?? '',
      enquiryId: json['enquiryId'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      quotationDate: json['quotationDate'] != null
          ? DateTime.tryParse(json['quotationDate'])
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.tryParse(json['validUntil'])
          : null,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      status: json['status'] ?? '',
      pdfPath: json['pdfPath'],
      items: items,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'quotationNumber': quotationNumber,
      'taxPercentage': taxPercentage,
      'notes': notes,
    };
  }
}
