enum RenderDimensionMode {
  mode3D,
  mode2D,
}

extension RenderDimensionModeX on RenderDimensionMode {
  String get label {
    switch (this) {
      case RenderDimensionMode.mode3D:
        return '3D Tüp Simülasyonu';
      case RenderDimensionMode.mode2D:
        return '2D Realistik İplik';
    }
  }
}

enum YarnMaterialPreset {
  cotton,
  wool,
  acrylic,
  mohair,
}

extension YarnMaterialPresetX on YarnMaterialPreset {
  String get label {
    switch (this) {
      case YarnMaterialPreset.cotton:
        return 'Pamuk (Cotton)';
      case YarnMaterialPreset.wool:
        return 'Yün (Wool)';
      case YarnMaterialPreset.acrylic:
        return 'Akrilik (Acrylic)';
      case YarnMaterialPreset.mohair:
        return 'Mohair (Tüylü)';
    }
  }

  double get defaultFuzziness {
    switch (this) {
      case YarnMaterialPreset.cotton:
        return 0.15;
      case YarnMaterialPreset.wool:
        return 0.45;
      case YarnMaterialPreset.acrylic:
        return 0.25;
      case YarnMaterialPreset.mohair:
        return 0.85;
    }
  }

  double get defaultThickness {
    switch (this) {
      case YarnMaterialPreset.cotton:
        return 1.8;
      case YarnMaterialPreset.wool:
        return 2.2;
      case YarnMaterialPreset.acrylic:
        return 2.0;
      case YarnMaterialPreset.mohair:
        return 1.5;
    }
  }

  double get shininess {
    switch (this) {
      case YarnMaterialPreset.cotton:
        return 18.0;
      case YarnMaterialPreset.wool:
        return 8.0;
      case YarnMaterialPreset.acrylic:
        return 28.0;
      case YarnMaterialPreset.mohair:
        return 5.0;
    }
  }
}

class YarnRenderConfig {
  final RenderDimensionMode renderDimension;
  final YarnMaterialPreset materialPreset;
  final double thickness;
  final double fuzziness;
  final double lightAngle; // in degrees
  final double cameraPitch; // X-axis rotation angle in radians
  final double cameraYaw; // Y-axis rotation angle in radians
  final double cameraZoom; // scale factor
  final Map<int, String> roundColors; // roundIndex -> hex color
  final bool showBackgroundGrid;
  final String backgroundColorHex;

  const YarnRenderConfig({
    this.renderDimension = RenderDimensionMode.mode3D,
    this.materialPreset = YarnMaterialPreset.cotton,
    this.thickness = 1.8,
    this.fuzziness = 0.2,
    this.lightAngle = 45.0,
    this.cameraPitch = 0.35,
    this.cameraYaw = -0.25,
    this.cameraZoom = 1.0,
    this.roundColors = const {},
    this.showBackgroundGrid = true,
    this.backgroundColorHex = '#F8FAFC',
  });

  YarnRenderConfig copyWith({
    RenderDimensionMode? renderDimension,
    YarnMaterialPreset? materialPreset,
    double? thickness,
    double? fuzziness,
    double? lightAngle,
    double? cameraPitch,
    double? cameraYaw,
    double? cameraZoom,
    Map<int, String>? roundColors,
    bool? showBackgroundGrid,
    String? backgroundColorHex,
  }) {
    return YarnRenderConfig(
      renderDimension: renderDimension ?? this.renderDimension,
      materialPreset: materialPreset ?? this.materialPreset,
      thickness: thickness ?? this.thickness,
      fuzziness: fuzziness ?? this.fuzziness,
      lightAngle: lightAngle ?? this.lightAngle,
      cameraPitch: cameraPitch ?? this.cameraPitch,
      cameraYaw: cameraYaw ?? this.cameraYaw,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      roundColors: roundColors ?? this.roundColors,
      showBackgroundGrid: showBackgroundGrid ?? this.showBackgroundGrid,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
    );
  }
}
