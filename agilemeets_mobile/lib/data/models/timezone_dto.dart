class TimeZoneDTO {
  final String? id;
  final String? displayName;
  final String? utcOffset;
  final bool isCommon;

  const TimeZoneDTO({
    this.id,
    this.displayName,
    this.utcOffset,
    this.isCommon = false,
  });

  factory TimeZoneDTO.fromJson(Map<String, dynamic> json) {
    return TimeZoneDTO(
      id: json['id'] as String?,
      displayName: json['displayName'] as String?,
      utcOffset: json['utcOffset'] as String?,
      isCommon: json['isCommon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'utcOffset': utcOffset,
    'isCommon': isCommon,
  };

  @override
  String toString() => '$displayName (${utcOffset ?? 'UTC'})';
} 