class ChartImage {
  final double x;
  final double y;
  final String filepath;
  final double width;
  final double height;
  final double rotation;
  final String zLayer;
  final int layer;

  ChartImage({
    this.x = 0,
    this.y = 0,
    this.filepath = '',
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.zLayer = 'front',
    this.layer = 0,
  });

  factory ChartImage.fromJson(Map<String, dynamic> json) {
    return ChartImage(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      filepath: json['filepath'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      zLayer: json['zLayer'] as String? ?? 'front',
      layer: json['layer'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'filepath': filepath,
      'width': width,
      'height': height,
      'rotation': rotation,
      'zLayer': zLayer,
      'layer': layer,
    };
  }
}