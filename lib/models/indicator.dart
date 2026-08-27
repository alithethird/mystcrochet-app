class Indicator {
  final double x;
  final double y;
  final String text;
  final String style;
  final String textColor;
  final String bgColor;
  final int layer;
  final double width;
  final double height;

  Indicator({
    this.x = 0,
    this.y = 0,
    this.text = '',
    this.style = '',
    this.textColor = '#000000',
    this.bgColor = '#ffffff',
    this.layer = 0,
    this.width = 100,
    this.height = 40,
  });

  factory Indicator.fromJson(Map<String, dynamic> json) {
    return Indicator(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      style: json['style'] as String? ?? '',
      textColor: json['textColor'] as String? ?? '#000000',
      bgColor: json['bgColor'] as String? ?? '#ffffff',
      layer: json['layer'] as int? ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 100,
      height: (json['height'] as num?)?.toDouble() ?? 40,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'text': text,
      'style': style,
      'textColor': textColor,
      'bgColor': bgColor,
      'layer': layer,
      'width': width,
      'height': height,
    };
  }
}