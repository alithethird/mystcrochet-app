enum GuidelinesType {
  textual(103),
  visual(104);

  final int value;
  const GuidelinesType(this.value);

  static GuidelinesType fromValue(int value) {
    return GuidelinesType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GuidelinesType.visual,
    );
  }
}

class Guidelines {
  final GuidelinesType type;
  final int visualRounds;
  final double visualRoundSpacing;
  final int visualRadialDivisions;
  final double visualSnapThreshold;
  final int visualShapeSides;
  final double visualCornerRatio;

  Guidelines({
    required this.type,
    this.visualRounds = 1,
    this.visualRoundSpacing = 50,
    this.visualRadialDivisions = 12,
    this.visualSnapThreshold = 50,
    this.visualShapeSides = 0,
    this.visualCornerRatio = 0.15,
  });

  factory Guidelines.fromJson(Map<String, dynamic> json) {
    return Guidelines(
      type: GuidelinesType.fromValue(json['type'] as int? ?? 104),
      visualRounds: json['visualRounds'] as int? ?? 1,
      visualRoundSpacing: (json['visualRoundSpacing'] as num?)?.toDouble() ?? 50,
      visualRadialDivisions: json['visualRadialDivisions'] as int? ?? 12,
      visualSnapThreshold: (json['visualSnapThreshold'] as num?)?.toDouble() ?? 50,
      visualShapeSides: json['visualShapeSides'] as int? ?? 0,
      visualCornerRatio: (json['visualCornerRatio'] as num?)?.toDouble() ?? 0.15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'visualRounds': visualRounds,
      'visualRoundSpacing': visualRoundSpacing,
      'visualRadialDivisions': visualRadialDivisions,
      'visualSnapThreshold': visualSnapThreshold,
      if (visualShapeSides != 0) 'visualShapeSides': visualShapeSides,
      if (visualCornerRatio != 0.15) 'visualCornerRatio': visualCornerRatio,
    };
  }

  Guidelines copyWith({
    GuidelinesType? type,
    int? visualRounds,
    double? visualRoundSpacing,
    int? visualRadialDivisions,
    double? visualSnapThreshold,
    int? visualShapeSides,
    double? visualCornerRatio,
  }) {
    return Guidelines(
      type: type ?? this.type,
      visualRounds: visualRounds ?? this.visualRounds,
      visualRoundSpacing: visualRoundSpacing ?? this.visualRoundSpacing,
      visualRadialDivisions: visualRadialDivisions ?? this.visualRadialDivisions,
      visualSnapThreshold: visualSnapThreshold ?? this.visualSnapThreshold,
      visualShapeSides: visualShapeSides ?? this.visualShapeSides,
      visualCornerRatio: visualCornerRatio ?? this.visualCornerRatio,
    );
  }
}
