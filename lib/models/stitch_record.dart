class StitchRecord {
  final String name;
  final String description;
  final String category;
  final String wrongSide;
  final String svgContent;

  StitchRecord({
    required this.name,
    required this.description,
    required this.category,
    required this.wrongSide,
    required this.svgContent,
  });

  factory StitchRecord.fromJson(Map<String, dynamic> json) {
    return StitchRecord(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      wrongSide: json['wrongSide'] as String? ?? '',
      svgContent: json['svgContent'] as String? ?? '',
    );
  }
}