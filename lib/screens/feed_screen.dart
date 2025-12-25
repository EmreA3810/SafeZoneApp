import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/image_from_string.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/report_model.dart';
import 'add_report_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ReportStatus? _selectedStatusFilter;
  ReportCategory? _selectedCategoryFilter;

  bool get _hasFilters =>
      _selectedStatusFilter != null || _selectedCategoryFilter != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportService = Provider.of<ReportService>(context, listen: false);
      reportService.loadCachedReportsIfNeeded();
      reportService.fetchReports();
    });
  }

  List<Report> _filterReports(List<Report> reports) {
    var filtered = reports;

    // Filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered
          .where((report) => report.status == _selectedStatusFilter)
          .toList();
    }

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((report) => report.category == _selectedCategoryFilter)
          .toList();
    }

    return filtered;
  }

  void _openSearch() {
    final reportService = Provider.of<ReportService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    showSearch(
      context: context,
      delegate: ReportSearchDelegate(
        reports: reportService.reports,
        currentUserId: authService.currentUser?.uid ?? '',
        onLike: (reportId) {
          if (authService.currentUser != null) {
            reportService.toggleLike(reportId, authService.currentUser!.uid);
          }
        },
      ),
    );
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
            onPressed: _openSearch,
            tooltip: 'Search reports',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Status Filter Button
                Expanded(
                  child: PopupMenuButton<ReportStatus?>(
                    tooltip: 'Filter by Status',
                    onSelected: (value) {
                      setState(() => _selectedStatusFilter = value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStatusFilter != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatusFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 18,
                            color: _selectedStatusFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedStatusFilter != null
                                  ? _selectedStatusFilter!.displayName
                                  : 'Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedStatusFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedStatusFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: ReportStatus.pending,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ReportStatus.pending.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportStatus.approved,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ReportStatus.approved.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportStatus.inProgress,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ReportStatus.inProgress.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportStatus.resolved,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ReportStatus.resolved.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportStatus.rejected,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ReportStatus.rejected.displayName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Category Filter Button
                Expanded(
                  child: PopupMenuButton<ReportCategory?>(
                    tooltip: 'Filter by Category',
                    onSelected: (value) {
                      setState(() => _selectedCategoryFilter = value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCategoryFilter != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategoryFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            size: 18,
                            color: _selectedCategoryFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedCategoryFilter != null
                                  ? _selectedCategoryFilter!.displayName
                                  : 'Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategoryFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedCategoryFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: ReportCategory.roadHazard,
                        child: Row(
                          children: [
                            const Icon(Icons.warning, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.roadHazard.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.streetlight,
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.streetlight.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.graffiti,
                        child: Row(
                          children: [
                            const Icon(Icons.brush, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.graffiti.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.waste,
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.waste.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.noise,
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.noise.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.parking,
                        child: Row(
                          children: [
                            const Icon(Icons.local_parking, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.parking.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.lostPet,
                        child: Row(
                          children: [
                            const Icon(Icons.pets, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.lostPet.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.foundPet,
                        child: Row(
                          children: [
                            const Icon(Icons.pets, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.foundPet.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportCategory.other,
                        child: Row(
                          children: [
                            const Icon(Icons.info, size: 18),
                            const SizedBox(width: 8),
                            Text(ReportCategory.other.displayName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasFilters) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatusFilter = null;
                        _selectedCategoryFilter = null;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Offline banner
          if (reportService.isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.secondary),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Theme.of(context).colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline: showing cached reports',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Reports list
          Expanded(
            // Show spinner only when loading AND there is no data yet.
            child: (reportService.isLoading && filteredReports.isEmpty)
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reports found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to report an issue!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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

// Search Delegate for searching reports
class ReportSearchDelegate extends SearchDelegate<Report?> {
  final List<Report> reports;
  final String currentUserId;
  final Function(String) onLike;

  ReportSearchDelegate({
    required this.reports,
    required this.currentUserId,
    required this.onLike,
  });

  @override
  String get searchFieldLabel => 'Search by title, category, or location';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by title, category, or location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final searchQuery = query.toLowerCase();
    final results = reports.where((report) {
      return report.title.toLowerCase().contains(searchQuery) ||
          report.description.toLowerCase().contains(searchQuery) ||
          report.category.displayName.toLowerCase().contains(searchQuery) ||
          report.locationAddress.toLowerCase().contains(searchQuery) ||
          report.userName.toLowerCase().contains(searchQuery);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final report = results[index];
        return ReportCard(
          report: report,
          currentUserId: currentUserId,
          onLike: () => onLike(report.id!),
        );
      },
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
                report.status.displayName,
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
                    report.category.displayName,
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
                  ],
                ),
                const SizedBox(height: 12),
                // Admin controls
                Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final isAdmin = auth.currentAppUser?.role.isAdmin ?? false;
                    if (!isAdmin) return const SizedBox.shrink();
                    final reportService = Provider.of<ReportService>(
                      context,
                      listen: false,
                    );
                    return PopupMenuButton<String>(
                      tooltip: 'Admin Controls',
                      icon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Admin Controls',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddReportScreen(existingReport: report),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Report'),
                              content: const Text(
                                'Are you sure you want to delete this report?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await reportService.deleteReport(
                                report.id!,
                                report.userId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report deleted'),
                                  ),
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
                        }
                      },
                      itemBuilder: (context) => [
                        // Status submenu
                        PopupMenuItem<String>(
                          enabled: false,
                          child: PopupMenuButton<ReportStatus>(
                            tooltip: 'Change Status',
                            onSelected: (status) async {
                              try {
                                await reportService.updateReportStatus(
                                  report.id!,
                                  status,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status updated'),
                                    ),
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
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: ReportStatus.pending,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pending'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ReportStatus.approved,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Approved'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ReportStatus.inProgress,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_bottom,
                                      size: 18,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 8),
                                    Text('In Progress'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ReportStatus.resolved,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.done_all,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Resolved'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ReportStatus.rejected,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Rejected'),
                                  ],
                                ),
                              ),
                            ],
                            child: const ListTile(
                              leading: Icon(Icons.flag),
                              title: Text('Change Status'),
                              trailing: Icon(Icons.arrow_right),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Report'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete Report',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
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
