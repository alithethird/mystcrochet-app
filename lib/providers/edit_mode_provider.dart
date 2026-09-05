import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditMode {
  stitch,
  color,
  rotation,
  scale,
  indicator,
  pan,
  visualPlace,
  visualSelect,
  move,
  delete,
}

class EditModeState {
  final EditMode mode;
  final double zoom;
  final String paintColor;
  final String paintTarget; // 'fg' or 'bg'

  EditModeState({
    this.mode = EditMode.stitch,
    this.zoom = 1.0,
    this.paintColor = '#000000',
    this.paintTarget = 'fg',
  });

  EditModeState copyWith({
    EditMode? mode,
    double? zoom,
    String? paintColor,
    String? paintTarget,
  }) {
    return EditModeState(
      mode: mode ?? this.mode,
      zoom: zoom ?? this.zoom,
      paintColor: paintColor ?? this.paintColor,
      paintTarget: paintTarget ?? this.paintTarget,
    );
  }
}

class EditModeNotifier extends StateNotifier<EditModeState> {
  EditModeNotifier() : super(EditModeState());

  void setMode(EditMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.25, 4.0));
  }

  void setPaintColor(String color) {
    state = state.copyWith(paintColor: color);
  }

  void setPaintTarget(String target) {
    state = state.copyWith(paintTarget: target);
  }
}

final editModeProvider = StateNotifierProvider<EditModeNotifier, EditModeState>((ref) {
  return EditModeNotifier();
});