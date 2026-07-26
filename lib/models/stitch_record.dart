class StitchRecord {
  final String name;
  final String description;
  final List<String> category;
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
      category: _parseCategory(json['category']),
      wrongSide: json['wrongSide'] as String? ?? '',
      svgContent: json['svgContent'] as String? ?? '',
    );
  }

  static List<String> _parseCategory(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return <String>[];
      }
      return <String>[trimmed];
    }

    return <String>[];
  }
}