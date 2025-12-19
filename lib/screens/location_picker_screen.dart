import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _fallbackLocation = LatLng(40.7128, -74.0060); // NYC
  static const double _defaultZoom = 15;

  late MapController _mapController;
  late LatLng _selectedLocation;
  String _address = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? _fallbackLocation;
    if (widget.initialLocation == null) {
      _getCurrentLocation();
    } else {
      _getAddressFromLocation(_selectedLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation, _defaultZoom);
      _getAddressFromLocation(_selectedLocation);
    } catch (e) {
      // Use default location if getting current location fails
      _mapController.move(_selectedLocation, _defaultZoom);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = _formatAddress(place);
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to get address';
        _isLoadingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    final parts = [
      place.street,
      place.locality,
      place.administrativeArea,
      place.country,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unnamed location';
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _defaultZoom,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safezone',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Address display
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _isLoadingAddress
                        ? const LinearProgressIndicator()
                        : Text(
                            _address,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      'Drag the pin to the exact location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FilledButton(
              onPressed: _confirmLocation,
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
