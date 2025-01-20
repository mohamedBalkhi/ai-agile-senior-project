class CountryDTO {
  final String id;
  final String? name;
  final String? code;

  CountryDTO({required this.id, this.name, this.code});

  factory CountryDTO.fromJson(Map<String, dynamic> json) {
    return CountryDTO(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }
}
