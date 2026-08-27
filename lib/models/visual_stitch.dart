class VisualStitch {
  final String id;
  final String stitchName;
  final double x;
  final double y;
  final int roundIndex;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final String fgColor;
  final String bgColor;
  final int layer;

  VisualStitch({
    required this.id,
    required this.stitchName,
    required this.x,
    required this.y,
    this.roundIndex = -1,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.fgColor = '#000000',
    this.bgColor = '#ffffff',
    this.layer = 0,
  });

  factory VisualStitch.fromJson(Map<String, dynamic> json) {
    return VisualStitch(
      id: json['id'] as String? ?? '',
      stitchName: json['stitchName'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      roundIndex: json['roundIndex'] as int? ?? -1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1,
      fgColor: json['fgColor'] as String? ?? '#000000',
      bgColor: json['bgColor'] as String? ?? '#ffffff',
      layer: json['layer'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stitchName': stitchName,
      'x': x,
      'y': y,
      'roundIndex': roundIndex,
      'rotation': rotation,
      'scaleX': scaleX,
      'scaleY': scaleY,
      'fgColor': fgColor,
      'bgColor': bgColor,
      'layer': layer,
    };
  }

  VisualStitch copyWith({
    String? id,
    String? stitchName,
    double? x,
    double? y,
    int? roundIndex,
    double? rotation,
    double? scaleX,
    double? scaleY,
    String? fgColor,
    String? bgColor,
    int? layer,
  }) {
    return VisualStitch(
      id: id ?? this.id,
      stitchName: stitchName ?? this.stitchName,
      x: x ?? this.x,
      y: y ?? this.y,
      roundIndex: roundIndex ?? this.roundIndex,
      rotation: rotation ?? this.rotation,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      fgColor: fgColor ?? this.fgColor,
      bgColor: bgColor ?? this.bgColor,
      layer: layer ?? this.layer,
    );
  }
}