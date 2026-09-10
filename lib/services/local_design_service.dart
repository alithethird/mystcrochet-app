import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chart.dart';

class SavedDesign {
  final String id;
  final String name;
  final DateTime updatedAt;
  final int roundCount;
  final int stitchCount;
  final Map<String, dynamic> chartData;

  SavedDesign({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.roundCount,
    required this.stitchCount,
    required this.chartData,
  });

  factory SavedDesign.fromChart(Chart chart, {String? id, String? name}) {
    final effectiveName = name ?? (chart.name.trim().isNotEmpty ? chart.name.trim() : 'İsimsiz Tasarım');
    int totalStitches = 0;
    for (final round in chart.patternRounds) {
      for (final s in round.stitches) {
        totalStitches += s.count ?? 1;
      }
    }
    totalStitches += chart.visualStitches.length;

    return SavedDesign(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: effectiveName,
      updatedAt: DateTime.now(),
      roundCount: chart.patternRounds.length,
      stitchCount: totalStitches,
      chartData: chart.toJson(),
    );
  }

  Chart toChart() => Chart.fromJson(chartData);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'updatedAt': updatedAt.toIso8601String(),
        'roundCount': roundCount,
        'stitchCount': stitchCount,
        'chartData': chartData,
      };

  factory SavedDesign.fromJson(Map<String, dynamic> json) {
    return SavedDesign(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'İsimsiz',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      roundCount: json['roundCount'] as int? ?? 0,
      stitchCount: json['stitchCount'] as int? ?? 0,
      chartData: (json['chartData'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class LocalDesignService {
  static const String _savedDesignsKey = 'crochet_saved_designs';
  static const String _activeDraftKey = 'crochet_active_draft';

  /// Returns all designs saved locally, sorted newest to oldest.
  static Future<List<SavedDesign>> getSavedDesigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedDesignsKey);
      if (raw == null || raw.isEmpty) return [];

      final list = json.decode(raw) as List<dynamic>;
      final designs = list
          .map((item) => SavedDesign.fromJson(item as Map<String, dynamic>))
          .toList();
      designs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return designs;
    } catch (_) {
      return [];
    }
  }

  /// Saves or updates a design in local storage.
  static Future<SavedDesign> saveDesign(Chart chart, {String? id, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final designs = await getSavedDesigns();

    final targetId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final effectiveName = name ?? (chart.name.trim().isNotEmpty ? chart.name.trim() : 'İsimsiz Tasarım');
    final newDesign = SavedDesign.fromChart(
      chart.copyWith(name: effectiveName),
      id: targetId,
      name: effectiveName,
    );

    final existingIndex = designs.indexWhere((d) => d.id == targetId);
    if (existingIndex >= 0) {
      designs[existingIndex] = newDesign;
    } else {
      designs.insert(0, newDesign);
    }

    designs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final encoded = json.encode(designs.map((d) => d.toJson()).toList());
    await prefs.setString(_savedDesignsKey, encoded);
    return newDesign;
  }

  /// Deletes a saved design by ID.
  static Future<bool> deleteDesign(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final designs = await getSavedDesigns();
      final initialCount = designs.length;
      designs.removeWhere((d) => d.id == id);
      if (designs.length == initialCount) return false;

      final encoded = json.encode(designs.map((d) => d.toJson()).toList());
      await prefs.setString(_savedDesignsKey, encoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves a specific saved design by ID.
  static Future<SavedDesign?> getDesign(String id) async {
    final designs = await getSavedDesigns();
    try {
      return designs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Auto-saves the currently active canvas draft to localStorage.
  static Future<void> saveActiveDraft(Chart chart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(chart.toJson());
      await prefs.setString(_activeDraftKey, jsonStr);
    } catch (_) {}
  }

  /// Loads the auto-saved draft if present.
  static Future<Chart?> loadActiveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_activeDraftKey);
      if (raw == null || raw.isEmpty) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      return Chart.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears the auto-saved draft.
  static Future<void> clearActiveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeDraftKey);
    } catch (_) {}
  }
}
