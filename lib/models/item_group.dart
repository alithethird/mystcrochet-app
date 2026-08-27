class ItemGroup {
  final List<List<int>> cellIndices;
  final int layer;

  ItemGroup({
    this.cellIndices = const [],
    this.layer = 0,
  });

  factory ItemGroup.fromJson(Map<String, dynamic> json) {
    final cells = json['cells'] as List? ?? [];
    return ItemGroup(
      cellIndices: cells.map((c) => (c as List).map((e) => e as int).toList()).toList(),
      layer: json['layer'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cells': cellIndices,
      'layer': layer,
    };
  }
}