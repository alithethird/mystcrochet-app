import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoredSettings {
  int defaultCellSize;
  bool gridSnap;
  String theme;
  List<Map<String, String>> recentFiles;
  String defaultFgColor;
  String defaultBgColor;
  String defaultStitch;
  int defaultGridStyle;
  bool confirmClose;
  int defaultRows;
  int defaultCols;
  String rowIndicatorStyle;

  StoredSettings({
    this.defaultCellSize = 100,
    this.gridSnap = false,
    this.theme = 'light',
    this.recentFiles = const [],
    this.defaultFgColor = '#000000',
    this.defaultBgColor = '#ffffff',
    this.defaultStitch = 'sc',
    this.defaultGridStyle = 100,
    this.confirmClose = true,
    this.defaultRows = 10,
    this.defaultCols = 10,
    this.rowIndicatorStyle = 'numbers',
  });

  static const _key = 'crochet_charts_settings';

  factory StoredSettings.fromJson(Map<String, dynamic> json) {
    return StoredSettings(
      defaultCellSize: json['defaultCellSize'] as int? ?? 100,
      gridSnap: json['gridSnap'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'light',
      recentFiles: ((json['recentFiles'] as List?) ?? [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      defaultFgColor: json['defaultFgColor'] as String? ?? '#000000',
      defaultBgColor: json['defaultBgColor'] as String? ?? '#ffffff',
      defaultStitch: json['defaultStitch'] as String? ?? 'sc',
      defaultGridStyle: json['defaultGridStyle'] as int? ?? 100,
      confirmClose: json['confirmClose'] as bool? ?? true,
      defaultRows: json['defaultRows'] as int? ?? 10,
      defaultCols: json['defaultCols'] as int? ?? 10,
      rowIndicatorStyle: json['rowIndicatorStyle'] as String? ?? 'numbers',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCellSize': defaultCellSize,
      'gridSnap': gridSnap,
      'theme': theme,
      'recentFiles': recentFiles,
      'defaultFgColor': defaultFgColor,
      'defaultBgColor': defaultBgColor,
      'defaultStitch': defaultStitch,
      'defaultGridStyle': defaultGridStyle,
      'confirmClose': confirmClose,
      'defaultRows': defaultRows,
      'defaultCols': defaultCols,
      'rowIndicatorStyle': rowIndicatorStyle,
    };
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(toJson()));
  }

  static Future<StoredSettings> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        return StoredSettings.fromJson(map);
      } catch (_) {}
    }
    return StoredSettings();
  }
}