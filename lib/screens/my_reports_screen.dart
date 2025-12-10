import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/image_from_string.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/report_model.dart';
import 'add_report_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Report> _userReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReports();
  }

  Future<void> _loadUserReports() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final reportService = Provider.of<ReportService>(context, listen: false);

    if (authService.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final reports = await reportService.fetchUserReports(
        authService.currentUser!.uid,
      );
      setState(() {
        _userReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load reports: $e')));
      }
    }
  }

  Future<void> _deleteReport(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reportService = Provider.of<ReportService>(
          context,
          listen: false,
        );
        final authService = Provider.of<AuthService>(context, listen: false);

        await reportService.deleteReport(
          report.id!,
          authService.currentUser!.uid,
        );

        await _loadUserReports();

        // Refresh user data so profile report count stays in sync
        await authService.refreshUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editReport(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReportScreen(existingReport: report),
      ),
    ).then((_) => _loadUserReports());
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.blue;
      case ReportStatus.inProgress:
        return Colors.amber;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: authService.currentUser == null
          ? const Center(child: Text('Please sign in to view your reports'))
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userReports.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadUserReports,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by creating your first report!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserReports,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _userReports.length,
                itemBuilder: (context, index) {
                  final report = _userReports[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (report.photoUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ImageFromString(
                                src: report.photoUrls.first,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date
                              Text(
                                timeago.format(report.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                report.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              // Status
                              Chip(
                                label: Text(
                                  report.getStatusDisplayName(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: _getStatusColor(
                                  report.status,
                                ).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _getStatusColor(report.status),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                report.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),

                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _editReport(report),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _deleteReport(report),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
