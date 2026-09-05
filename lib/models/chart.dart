import 'layer.dart';
import 'indicator.dart';
import 'chart_image.dart';
import 'item_group.dart';
import 'guidelines.dart';
import 'visual_stitch.dart';
import 'pattern.dart';

class Chart {
  final String name;
  final GuidelinesType style;
  final Guidelines guidelines;
  final Map<int, ChartLayer> layers;
  final List<Indicator> indicators;
  final List<ChartImage> images;
  final List<ItemGroup> groups;
  final List<VisualStitch> visualStitches;
  final List<PatternRound> patternRounds;
  final String? starterStitchName;

  Chart({
    this.name = '',
    this.style = GuidelinesType.visual,
    required this.guidelines,
    this.layers = const {},
    this.indicators = const [],
    this.images = const [],
    this.groups = const [],
    this.visualStitches = const [],
    this.patternRounds = const [],
    this.starterStitchName,
  });

  factory Chart.defaultChart() {
    return Chart(
      name: 'Untitled',
      style: GuidelinesType.visual,
      guidelines: Guidelines(type: GuidelinesType.visual),
      layers: {0: ChartLayer(uid: 0, name: 'Layer 1')},
      visualStitches: [],
      patternRounds: [],
    );
  }

  factory Chart.fromJson(Map<String, dynamic> json) {
    final guidelinesRaw = json['guidelines'] as Map<String, dynamic>? ?? {};
    final layersRaw = json['layers'] as Map<String, dynamic>? ?? {};
    final indicatorsRaw = json['indicators'] as List? ?? [];
    final imagesRaw = json['images'] as List? ?? [];
    final groupsRaw = json['groups'] as List? ?? [];
    final visualStitchesRaw = json['visualStitches'] as List? ?? [];
    final patternRoundsRaw = json['patternRounds'] as List? ?? [];

    return Chart(
      name: json['name'] as String? ?? '',
      style: GuidelinesType.fromValue(json['style'] as int? ?? 104),
      guidelines: Guidelines.fromJson(guidelinesRaw),
      layers: layersRaw.map((k, v) => MapEntry(
        int.parse(k),
        ChartLayer.fromJson(v as Map<String, dynamic>),
      )),
      indicators: indicatorsRaw.map((i) => Indicator.fromJson(i as Map<String, dynamic>)).toList(),
      images: imagesRaw.map((i) => ChartImage.fromJson(i as Map<String, dynamic>)).toList(),
      groups: groupsRaw.map((g) => ItemGroup.fromJson(g as Map<String, dynamic>)).toList(),
      visualStitches: visualStitchesRaw.map((v) => VisualStitch.fromJson(v as Map<String, dynamic>)).toList(),
      patternRounds: patternRoundsRaw.map((r) => PatternRound.fromJson(r as Map<String, dynamic>)).toList(),
      starterStitchName: json['starterStitchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'style': style.value,
      'guidelines': guidelines.toJson(),
      'layers': layers.map((k, v) => MapEntry(k.toString(), v.toJson())),
      'indicators': indicators.map((i) => i.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'visualStitches': visualStitches.map((v) => v.toJson()).toList(),
      'patternRounds': patternRounds.map((r) => r.toJson()).toList(),
      if (starterStitchName != null) 'starterStitchName': starterStitchName,
    };
  }

  Chart copyWith({
    String? name,
    GuidelinesType? style,
    Guidelines? guidelines,
    Map<int, ChartLayer>? layers,
    List<Indicator>? indicators,
    List<ChartImage>? images,
    List<ItemGroup>? groups,
    List<VisualStitch>? visualStitches,
    List<PatternRound>? patternRounds,
    String? starterStitchName,
    bool clearStarterStitch = false,
  }) {
    return Chart(
      name: name ?? this.name,
      style: style ?? this.style,
      guidelines: guidelines ?? this.guidelines,
      layers: layers ?? this.layers,
      indicators: indicators ?? this.indicators,
      images: images ?? this.images,
      groups: groups ?? this.groups,
      visualStitches: visualStitches ?? this.visualStitches,
      patternRounds: patternRounds ?? this.patternRounds,
      starterStitchName: clearStarterStitch ? null : (starterStitchName ?? this.starterStitchName),
    );
  }
}
