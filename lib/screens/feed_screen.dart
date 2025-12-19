import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/image_from_string.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import 'add_report_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ReportStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportService>(context, listen: false).fetchReports();
    });
  }

  List<Report> _filterReports(List<Report> reports) {
    if (_selectedFilter == null) {
      return reports;
    }
    return reports.where((report) => report.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context);
    final authService = Provider.of<AuthService>(context);
    final filteredReports = _filterReports(reportService.reports);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work_rounded),
            SizedBox(width: 8),
            Text('Community Watch'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              // TODO; Implement filter
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _selectedFilter == ReportStatus.pending,
                  onSelected: (selected) {
                    setState(
                      () => _selectedFilter = selected
                          ? ReportStatus.pending
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('In Progress'),
                  selected: _selectedFilter == ReportStatus.inProgress,
                  onSelected: (selected) {
                    setState(
                      () => _selectedFilter = selected
                          ? ReportStatus.inProgress
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Resolved'),
                  selected: _selectedFilter == ReportStatus.resolved,
                  onSelected: (selected) {
                    setState(
                      () => _selectedFilter = selected
                          ? ReportStatus.resolved
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),

          // Reports list
          Expanded(
            child: reportService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => reportService.fetchReports(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reports found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to report an issue!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
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
                        onRefresh: () => reportService.fetchReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return ReportCard(
                              report: report,
                              currentUserId: authService.currentUser?.uid ?? '',
                              onLike: () {
                                if (authService.currentUser != null) {
                                  reportService.toggleLike(
                                    report.id!,
                                    authService.currentUser!.uid,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class ReportCard extends StatefulWidget {
  final Report report;
  final String currentUserId;
  final VoidCallback onLike;

  const ReportCard({
    super.key,
    required this.report,
    required this.currentUserId,
    required this.onLike,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPageIndex = _pageController.page?.round() ?? 0;
    });
  }

  Color _getStatusColor(BuildContext context) {
    switch (widget.report.status) {
      case ReportStatus.approved:
        return Colors.green;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.grey;
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final currentUserId = widget.currentUserId;
    final isLiked = report.likedBy.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: CircleAvatar(
                backgroundImage: report.userPhotoUrl != null
                  ? NetworkImage(report.userPhotoUrl!) as ImageProvider
                  : null,
              child: report.userPhotoUrl == null
                  ? Text(report.userName[0].toUpperCase())
                  : null,
            ),
            title: Text(report.userName),
            subtitle: Text(timeago.format(report.createdAt)),
            trailing: Chip(
              label: Text(
                report.getStatusDisplayName(),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getStatusColor(context).withOpacity(0.2),
              labelStyle: TextStyle(color: _getStatusColor(context)),
              padding: EdgeInsets.zero,
            ),
          ),

          // Images carousel
          if (report.photoUrls.isNotEmpty)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: report.photoUrls.length,
                    itemBuilder: (context, index) {
                      return ImageFromString(
                        src: report.photoUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                // Image counter badge
                if (report.photoUrls.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPageIndex + 1}/${report.photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                Chip(
                  label: Text(
                    report.getCategoryDisplayName(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  report.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.locationAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      ),
                      onPressed: widget.onLike,
                      color: isLiked
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    Text('${report.likes}'),
                    const SizedBox(width: 16),
                    /*const Icon(Icons.comment_outlined),
                    const SizedBox(width: 4),
                    Text('${report.comments}'),*/
                  ],
                ),
                const SizedBox(height: 12),
                // Admin controls
                Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final isAdmin = auth.currentAppUser?.role == UserRole.admin;
                    if (!isAdmin) return const SizedBox.shrink();
                    final reportService = Provider.of<ReportService>(context, listen: false);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin Controls',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Status change
                              PopupMenuButton<ReportStatus>(
                                tooltip: 'Change status',
                                onSelected: (status) async {
                                  try {
                                    await reportService.updateReportStatus(report.id!, status);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Status updated')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: $e')),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => ReportStatus.values
                                    .map((s) => PopupMenuItem(
                                          value: s,
                                          child: Text(s.name),
                                        ))
                                    .toList(),
                                child: OutlinedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.flag_outlined, size: 16),
                                  label: const Text('Status'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                              // Edit
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddReportScreen(existingReport: report),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                              // Delete
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Report'),
                                      content: const Text('Are you sure?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await reportService.deleteReport(report.id!, report.userId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Report deleted')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
