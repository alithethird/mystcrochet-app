import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart.dart';

class ChartState {
  final Chart chart;
  final bool canUndo;
  final bool canRedo;

  ChartState({required this.chart, this.canUndo = false, this.canRedo = false});

  ChartState copyWith({Chart? chart, bool? canUndo, bool? canRedo}) {
    return ChartState(
      chart: chart ?? this.chart,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class ChartNotifier extends StateNotifier<ChartState> {
  final List<Chart> _undoStack = [];
  final List<Chart> _redoStack = [];
  static const int _maxHistory = 50;

  ChartNotifier() : super(ChartState(chart: Chart.defaultChart()));

  Chart get chart => state.chart;

  void setChart(Chart newChart) {
    _undoStack.add(state.chart);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
    state = state.copyWith(chart: newChart, canUndo: true, canRedo: false);
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
