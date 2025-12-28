import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../widgets/image_from_string.dart';
import '../services/auth_service.dart';


class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

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
    final ref = FirebaseDatabase.instance.ref('reports/$reportId');

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Report not found (ID: $reportId)', textAlign: TextAlign.center),
              ),
            );
          }

          if (data is Map) {
            final map = Map<String, dynamic>.from(data as Map);
            final report = Report.fromMap(reportId, map);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.photoUrls.isNotEmpty)
                        _DetailImageCarousel(photoUrls: report.photoUrls),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: user avatar + name + time
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: report.userPhotoUrl != null && report.userPhotoUrl!.isNotEmpty
                                      ? NetworkImage(report.userPhotoUrl!)
                                      : null,
                                  child: report.userPhotoUrl == null || report.userPhotoUrl!.isEmpty
                                      ? Text(
                                          report.userName.isNotEmpty ? report.userName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.userName.isNotEmpty ? report.userName : 'Anonymous',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        timeago.format(report.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              report.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),

                            // Category and Status chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(report.category.displayName),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(report.status.displayName),
                                  backgroundColor: _getStatusColor(report.status).withValues(alpha: 0.2),
                                  labelStyle: TextStyle(color: _getStatusColor(report.status)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              report.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.locationAddress,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions (like/comments)
                Builder(builder: (context) {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final currentUserId = auth.currentUser?.uid;
                  final isLiked = currentUserId != null && report.likedBy.contains(currentUserId);
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (currentUserId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please sign in to like reports')),
                              );
                              return;
                            }
                            try {
                              await Provider.of<ReportService>(context, listen: false)
                                  .toggleLike(reportId, currentUserId);
                            } catch (e) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Failed to like: $e')));
                            }
                          },
                          icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                          label: Text(isLiked ? 'Liked (${report.likes})' : 'Like (${report.likes})'),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
          }

          return const Center(child: Text('Unsupported report format'));
        },
      ),
    );
  }
}

class _DetailImageCarousel extends StatefulWidget {
  final List<String> photoUrls;
  const _DetailImageCarousel({required this.photoUrls});

  @override
  State<_DetailImageCarousel> createState() => _DetailImageCarouselState();
}

class _DetailImageCarouselState extends State<_DetailImageCarousel> {
  late final PageController _pageController;
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photoUrls.length,
              itemBuilder: (context, index) {
                return ImageFromString(src: widget.photoUrls[index], fit: BoxFit.cover);
              },
            ),
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${_currentPageIndex + 1}/${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
