import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/stitch_record.dart';

class StitchStore {
  List<StitchRecord> _all = [];
  String _searchText = '';
  String? _activeCategory;
  String? _activeStitchName;

  List<StitchRecord> get all => _all;
  String get searchText => _searchText;
  String? get activeCategory => _activeCategory;
  String? get activeStitchName => _activeStitchName;

  List<StitchRecord> get filtered {
    var result = _all;
    if (_activeCategory != null) {
      result = result.where((s) => s.category == _activeCategory).toList();
    }
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  List<String> get categories {
    return _all.map((s) => s.category).toSet().toList()..sort();
  }

  StitchRecord? getStitch(String name) {
    try {
      return _all.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final jsonStr = await rootBundle.loadString('assets/stitches.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = (data['stitches'] as List)
        .map((e) => StitchRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _all = list;
  }

  void setSearchText(String v) {
    _searchText = v;
  }

  void setActiveCategory(String? v) {
    _activeCategory = v;
  }

  void setActiveStitchName(String? v) {
    _activeStitchName = v;
  }
}

final stitchStoreProvider = ChangeNotifierProvider<StitchStoreNotifier>((ref) {
  return StitchStoreNotifier();
});

class StitchStoreNotifier extends ChangeNotifier {
  final StitchStore _store = StitchStore();

  StitchStore get store => _store;
  List<StitchRecord> get all => _store.all;
  List<StitchRecord> get filtered => _store.filtered;
  List<String> get categories => _store.categories;
  String? get activeStitchName => _store.activeStitchName;

  StitchRecord? getStitch(String name) => _store.getStitch(name);

  Future<void> load() async {
    await _store.load();
    notifyListeners();
  }

  void setSearchText(String v) {
    _store.setSearchText(v);
    notifyListeners();
  }

  void setActiveCategory(String? v) {
    _store.setActiveCategory(v);
    notifyListeners();
  }

  void setActiveStitchName(String? v) {
    _store.setActiveStitchName(v);
    notifyListeners();
  }
}