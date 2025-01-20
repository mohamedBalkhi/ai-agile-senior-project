import '../enums/ai_processing_status.dart';

class MeetingAIReportDTO {
  final String? transcript;
  final String? summary;
  final List<String>? keyPoints;
  final String? mainLanguage;
  final AIProcessingStatus processingStatus;
  final DateTime? processedAt;

  const MeetingAIReportDTO({
    this.transcript,
    this.summary,
    this.keyPoints,
    this.mainLanguage,
    required this.processingStatus,
    this.processedAt,
  });

  factory MeetingAIReportDTO.fromJson(Map<String, dynamic> json) {
    return MeetingAIReportDTO(
      transcript: json['transcript'] as String?,
      summary: json['summary'] as String?,
      keyPoints: json['keyPoints'] != null
          ? List<String>.from(json['keyPoints'] as List)
          : null,
      mainLanguage: json['mainLanguage'] as String?,
      processingStatus: AIProcessingStatus.values[json['processingStatus'] as int],
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transcript': transcript,
      'summary': summary,
      'keyPoints': keyPoints,
      'mainLanguage': mainLanguage,
      'processingStatus': processingStatus.index,
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}
