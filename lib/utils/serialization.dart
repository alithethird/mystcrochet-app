import 'dart:convert';
import '../models/chart.dart';

String chartToJson(Chart chart) {
  return json.encode(chart.toJson());
}

Chart chartFromJson(String jsonStr) {
  final data = json.decode(jsonStr) as Map<String, dynamic>;
  final envelope = data['chart'] as Map<String, dynamic>?;
  return Chart.fromJson(envelope ?? data);
}