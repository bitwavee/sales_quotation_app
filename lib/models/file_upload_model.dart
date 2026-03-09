class FileUpload {
  final String id;
  final String enquiryId;
  final String fileName;
  final String? fileType;
  final int? fileSize;
  final String? filePath;
  final String? category;
  final DateTime uploadedAt;

  FileUpload({
    required this.id,
    required this.enquiryId,
    required this.fileName,
    this.fileType,
    this.fileSize,
    this.filePath,
    this.category,
    required this.uploadedAt,
  });

  factory FileUpload.fromJson(Map<String, dynamic> json) {
    return FileUpload(
      id: json['id'] ?? '',
      enquiryId: json['enquiryId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      filePath: json['filePath'],
      category: json['category'],
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
