import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart.dart';

class ChartState {
  final Chart chart;
  final bool canUndo;
  final bool canRedo;
  final int loadId;

  ChartState({
    required this.chart,
    this.canUndo = false,
    this.canRedo = false,
    this.loadId = 0,
  });

  ChartState copyWith({Chart? chart, bool? canUndo, bool? canRedo, int? loadId}) {
    return ChartState(
      chart: chart ?? this.chart,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      loadId: loadId ?? this.loadId,
    );
  }
}

class ChartNotifier extends StateNotifier<ChartState> {
  final List<Chart> _undoStack = [];
  final List<Chart> _redoStack = [];
  static const int _maxHistory = 50;

  ChartNotifier() : super(ChartState(chart: Chart.defaultChart()));

  Chart get chart => state.chart;

  /// Loads a brand new chart (e.g. file open or new document), resetting undo history and view.
  void loadChart(Chart newChart) {
    _undoStack.clear();
    _redoStack.clear();
    state = ChartState(
      chart: newChart,
      canUndo: false,
      canRedo: false,
      loadId: state.loadId + 1,
    );
  }

  /// Saves the current state to the undo stack before beginning a batch/drag mutation.
  void saveUndoCheckpoint() {
    _undoStack.add(state.chart);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
    state = state.copyWith(canUndo: true, canRedo: false);
  }

  void setChart(Chart newChart, {bool recordUndo = true}) {
    if (recordUndo) {
      _undoStack.add(state.chart);
      if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
      _redoStack.clear();
    }
    state = state.copyWith(
      chart: newChart,
      canUndo: _undoStack.isNotEmpty,
      canRedo: recordUndo ? false : state.canRedo,
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(state.chart);
    state = state.copyWith(
      chart: previous,
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
    );
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(state.chart);
    state = state.copyWith(
      chart: next,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
    );
  }
}

final chartProvider = StateNotifierProvider<ChartNotifier, ChartState>((ref) {
  return ChartNotifier();
});
