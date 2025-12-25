import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

class LocalReportCache {
  static const String _cacheKey = 'cached_reports';
  static const int _maxCacheSize = 20;

  /// Save reports to local cache (keeps last 20)
  static Future<void> saveReports(List<Report> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only the first 20 reports
      final reportsToCache = reports.take(_maxCacheSize).toList();
      
      final jsonList = reportsToCache.map((r) {
        final map = r.toMap();
        map['id'] = r.id; // Include ID in the map
        return map;
      }).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_cacheKey, jsonString);
      print('✅ Cached ${reportsToCache.length} reports locally');
    } catch (e) {
      print('❌ Error caching reports: $e');
    }
  }

  /// Load cached reports from local storage
  static Future<List<Report>> loadCachedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final reports = jsonList.map((json) {
        try {
          return Report.fromMap(json['id'] as String, json as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).whereType<Report>().toList();

      print('✅ Loaded ${reports.length} cached reports');
      return reports;
    } catch (e) {
      print('❌ Error loading cached reports: $e');
      return [];
    }
  }

  /// Clear cached reports
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('✅ Cleared report cache');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}
