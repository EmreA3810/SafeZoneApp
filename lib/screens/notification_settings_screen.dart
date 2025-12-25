import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../models/notification_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Map<ReportCategory, bool> _categoryNotifications;

  @override
  void initState() {
    super.initState();
    // Initialize with all enabled first to prevent null errors
    _categoryNotifications = {
      for (var category in ReportCategory.values) category: true,
    };
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await NotificationPreferences.load();
    setState(() {
      _categoryNotifications = prefs.categoryPreferences;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = NotificationPreferences(
      categoryPreferences: _categoryNotifications,
    );
    await prefs.save();
  }

  void _toggleAll(bool value) {
    setState(() {
      _categoryNotifications.updateAll((key, val) => value);
      _savePreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // General notifications section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Receive notifications for selected report categories',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Enable all / Disable all buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _toggleAll(true),
                    child: const Text('Enable All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _toggleAll(false),
                    child: const Text('Disable All'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category toggles
          ..._categoryNotifications.entries.map((entry) {
            final category = entry.key;
            final isEnabled = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: Text(category.displayName),
                subtitle: Text(_getCategoryDescription(category)),
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _categoryNotifications[category] = value;
                    _savePreferences();
                  });
                },
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          // Info section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive notifications when:\n'
                      '• New reports matching your preferences are posted\n'
                      '• The status of your reports changes\n'
                      '• Someone responds to your reports',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadHazard:
        return Icons.location_on;
      case ReportCategory.streetlight:
        return Icons.lightbulb;
      case ReportCategory.graffiti:
        return Icons.brush;
      case ReportCategory.waste:
        return Icons.delete;
      case ReportCategory.noise:
        return Icons.volume_up;
      case ReportCategory.parking:
        return Icons.local_parking;
      case ReportCategory.lostPet:
        return Icons.pets;
      case ReportCategory.foundPet:
        return Icons.pets;
      case ReportCategory.other:
        return Icons.info;
    }
  }

  String _getCategoryDescription(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadHazard:
        return 'Road damage and hazards';
      case ReportCategory.streetlight:
        return 'Broken or malfunctioning streetlights';
      case ReportCategory.graffiti:
        return 'Graffiti and vandalism';
      case ReportCategory.waste:
        return 'Illegal dumping and litter';
      case ReportCategory.noise:
        return 'Noise complaints';
      case ReportCategory.parking:
        return 'Parking violations';
      case ReportCategory.lostPet:
        return 'Lost pets';
      case ReportCategory.foundPet:
        return 'Found pets';
      case ReportCategory.other:
        return 'Other issues';
    }
  }
}
