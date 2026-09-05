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
  select,
  move,
  delete,
  replace,
}

class EditModeState {
  final EditMode mode;
  final double zoom;
  final String paintColor;
  final String paintTarget; // 'fg' or 'bg'
  final bool bulkReplace;
  final int? replaceRoundIdx;
  final int? replaceStitchIdx;
  final String? replaceStitchName;
  final int? replaceMatchCount;
  final Set<String> selectedStitchKeys;

  EditModeState({
    this.mode = EditMode.stitch,
    this.zoom = 1.0,
    this.paintColor = '#000000',
    this.paintTarget = 'fg',
    this.bulkReplace = false,
    this.replaceRoundIdx,
    this.replaceStitchIdx,
    this.replaceStitchName,
    this.replaceMatchCount,
    this.selectedStitchKeys = const {},
  });

  EditModeState copyWith({
    EditMode? mode,
    double? zoom,
    String? paintColor,
    String? paintTarget,
    bool? bulkReplace,
    int? replaceRoundIdx,
    int? replaceStitchIdx,
    String? replaceStitchName,
    int? replaceMatchCount,
    Set<String>? selectedStitchKeys,
    bool clearReplaceTarget = false,
  }) {
    return EditModeState(
      mode: mode ?? this.mode,
      zoom: zoom ?? this.zoom,
      paintColor: paintColor ?? this.paintColor,
      paintTarget: paintTarget ?? this.paintTarget,
      bulkReplace: bulkReplace ?? this.bulkReplace,
      replaceRoundIdx: clearReplaceTarget ? null : (replaceRoundIdx ?? this.replaceRoundIdx),
      replaceStitchIdx: clearReplaceTarget ? null : (replaceStitchIdx ?? this.replaceStitchIdx),
      replaceStitchName: clearReplaceTarget ? null : (replaceStitchName ?? this.replaceStitchName),
      replaceMatchCount: clearReplaceTarget ? null : (replaceMatchCount ?? this.replaceMatchCount),
      selectedStitchKeys: selectedStitchKeys ?? this.selectedStitchKeys,
    );
  }
}

class EditModeNotifier extends StateNotifier<EditModeState> {
  EditModeNotifier() : super(EditModeState());

  void setMode(EditMode mode) {
    if (mode != EditMode.replace) {
      state = state.copyWith(mode: mode, clearReplaceTarget: true);
    } else {
      state = state.copyWith(mode: mode);
    }
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

  void setBulkReplace(bool bulk) {
    state = state.copyWith(bulkReplace: bulk);
  }

  void setReplaceTarget({
    required int roundIdx,
    required int stitchIdx,
    required String stitchName,
    int? matchCount,
  }) {
    state = state.copyWith(
      replaceRoundIdx: roundIdx,
      replaceStitchIdx: stitchIdx,
      replaceStitchName: stitchName,
      replaceMatchCount: matchCount,
    );
  }

  void clearReplaceTarget() {
    state = state.copyWith(clearReplaceTarget: true);
  }

  void toggleStitchSelection(int roundIdx, int stitchIdx) {
    final key = '$roundIdx:$stitchIdx';
    final updated = Set<String>.from(state.selectedStitchKeys);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    state = state.copyWith(selectedStitchKeys: updated);
  }

  void clearSelection() {
    state = state.copyWith(selectedStitchKeys: const {});
  }

  void setSelection(Set<String> keys) {
    state = state.copyWith(selectedStitchKeys: keys);
  }
}

final editModeProvider = StateNotifierProvider<EditModeNotifier, EditModeState>((ref) {
  return EditModeNotifier();
});