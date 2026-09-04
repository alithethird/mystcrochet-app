import 'dart:convert';
import '../models/chart.dart';

String chartToJson(Chart chart) {
  return json.encode(chart.toJson());
}

Chart chartFromJson(String jsonStr) {
  final dynamic decoded = json.decode(jsonStr);
  if (decoded is! Map) {
    throw const FormatException('Invalid chart format: Root element is not a JSON object.');
  }
  final map = Map<String, dynamic>.from(decoded);
  final envelope = map['chart'];
  if (envelope is Map) {
    return Chart.fromJson(Map<String, dynamic>.from(envelope));
  }
  return Chart.fromJson(map);
}