class ChartLayer {
  final int uid;
  final String name;
  final bool visible;

  ChartLayer({
    required this.uid,
    required this.name,
    this.visible = true,
  });

  factory ChartLayer.fromJson(Map<String, dynamic> json) {
    return ChartLayer(
      uid: json['uid'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'visible': visible,
    };
  }
}