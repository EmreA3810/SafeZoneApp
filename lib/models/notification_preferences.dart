import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

class NotificationPreferences {
  final Map<ReportCategory, bool> categoryPreferences;

  NotificationPreferences({
    required this.categoryPreferences,
  });

  bool isEnabled(ReportCategory category) =>
      categoryPreferences[category] ?? true;

  int get enabledCategoriesCount =>
      categoryPreferences.values.where((v) => v).length;

  static NotificationPreferences _defaultPreferences() {
    return NotificationPreferences(
      categoryPreferences: {
        for (var category in ReportCategory.values) category: true,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryPreferences': {
        for (var entry in categoryPreferences.entries)
          entry.key.name: entry.value,
      },
    };
  }

  static NotificationPreferences fromJson(Map<String, dynamic> json) {
    final prefs = json['categoryPreferences'] as Map<String, dynamic>? ?? {};
    return NotificationPreferences(
      categoryPreferences: {
        for (var category in ReportCategory.values)
          category: prefs[category.name] ?? true,
      },
    );
  }

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notification_preferences');

    if (jsonString == null) {
      return _defaultPreferences();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      return _defaultPreferences();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notification_preferences',
      jsonEncode(toJson()),
    );
  }
}
