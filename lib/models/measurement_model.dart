import 'dart:convert';

class MeasurementCategory {
  final String id;
  final String categoryName;
  final String categoryKey;
  final List<String> measurementFields;

  MeasurementCategory({
    required this.id,
    required this.categoryName,
    required this.categoryKey,
    required this.measurementFields,
  });

  factory MeasurementCategory.fromJson(Map<String, dynamic> json) {
    List<String> fields = [];
    if (json['measurementFields'] is List) {
      fields = (json['measurementFields'] as List).map((e) => e.toString()).toList();
    } else if (json['measurementFields'] is String) {
      fields = (jsonDecode(json['measurementFields']) as List).map((e) => e.toString()).toList();
    }
    return MeasurementCategory(
      id: json['id'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryKey: json['categoryKey'] ?? '',
      measurementFields: fields,
    );
  }
}

class Measurement {
  final String id;
  final String enquiryId;
  final String categoryId;
  final MeasurementCategory? category;
  final Map<String, dynamic> measurementData;
  final double? calculatedValue;
  final String? notes;
  final DateTime createdAt;

  Measurement({
    required this.id,
    required this.enquiryId,
    required this.categoryId,
    this.category,
    required this.measurementData,
    this.calculatedValue,
    this.notes,
    required this.createdAt,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = {};
    if (json['measurementData'] is Map) {
      data = Map<String, dynamic>.from(json['measurementData']);
    } else if (json['measurementData'] is String) {
      data = Map<String, dynamic>.from(jsonDecode(json['measurementData']));
    }

    return Measurement(
      id: json['id'] ?? '',
      enquiryId: json['enquiryId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      category: json['category'] != null
          ? MeasurementCategory.fromJson(json['category'])
          : null,
      measurementData: data,
      calculatedValue: json['calculatedValue'] != null
          ? (json['calculatedValue'] as num).toDouble()
          : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'measurementData': measurementData,
      'notes': notes,
    };
  }
}
