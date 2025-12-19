import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallbackLocation = LatLng(40.7128, -74.0060); // NYC
  static const double _defaultZoom = 13;

  late MapController _mapController;
  LatLng _currentLocation = _fallbackLocation;
  Report? _selectedReport;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportService>(context, listen: false).fetchReports();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, _defaultZoom);
      }
    } catch (e) {
      // Use default location if getting current location fails
      _mapController.move(_currentLocation, _defaultZoom);
    }
  }

  Color _getMarkerColor(ReportStatus status) {
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

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadHazard:
        return Icons.warning;
      case ReportCategory.streetlight:
        return Icons.lightbulb;
      case ReportCategory.graffiti:
        return Icons.brush;
      case ReportCategory.lostPet:
      case ReportCategory.foundPet:
        return Icons.pets;
      case ReportCategory.parking:
        return Icons.local_parking;
      case ReportCategory.noise:
        return Icons.volume_up;
      case ReportCategory.waste:
        return Icons.delete;
      case ReportCategory.other:
        return Icons.info;
    }
  }

  void _openSearch() {
    final reportService = Provider.of<ReportService>(context, listen: false);
    showSearch(
      context: context,
      delegate: MapSearchDelegate(
        reports: reportService.reports,
        onReportSelected: (report) {
          setState(() {
            _selectedReport = report;
            _mapController.move(report.location, _defaultZoom);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ReportService>(context, listen: false).fetchReports();
            },
            tooltip: 'Refresh reports',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_currentLocation, _defaultZoom);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search reports',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _defaultZoom,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safezone',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  // Report markers
                  ...reportService.reports.map((report) {
                    return Marker(
                      point: report.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReport = report;
                          });
                        },
                        child: Icon(
                          _getCategoryIcon(report.category),
                          color: _getMarkerColor(report.status),
                          size: 32,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black45),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Report details card
          if (_selectedReport != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedReport!.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedReport = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_selectedReport!.category.displayName),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedReport!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedReport!.locationAddress,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_selectedReport!.status.displayName),
                        backgroundColor: _getMarkerColor(
                          _selectedReport!.status,
                        ).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getMarkerColor(_selectedReport!.status),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          // TODO: Navigate to report details
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendItem(color: Colors.orange, label: 'Pending'),
                    _LegendItem(color: Colors.amber, label: 'In Progress'),
                    _LegendItem(color: Colors.green, label: 'Resolved'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// Search Delegate for map screen
class MapSearchDelegate extends SearchDelegate<Report?> {
  final List<Report> reports;
  final Function(Report) onReportSelected;

  MapSearchDelegate({required this.reports, required this.onReportSelected});

  @override
  String get searchFieldLabel => 'Search reports on map';

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
              'Search reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Find reports by title, category, or location',
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
          report.locationAddress.toLowerCase().contains(searchQuery);
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
      itemCount: results.length,
      itemBuilder: (context, index) {
        final report = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
            child: Icon(
              Icons.location_on,
              color: _getStatusColor(report.status),
            ),
          ),
          title: Text(
            report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.category.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                report.locationAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: Chip(
            label: Text(
              report.status.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
            labelStyle: TextStyle(color: _getStatusColor(report.status)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            onReportSelected(report);
            close(context, report);
          },
        );
      },
    );
  }
}
