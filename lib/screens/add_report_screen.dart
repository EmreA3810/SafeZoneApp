import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/report_model.dart';
import 'location_picker_screen.dart';
import '../widgets/image_from_string.dart';

class AddReportScreen extends StatefulWidget {
  final Report? existingReport;

  const AddReportScreen({super.key, this.existingReport});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ReportCategory _selectedCategory = ReportCategory.other;
  final List<File> _images = [];
  LatLng? _selectedLocation;
  String _locationAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReport != null) {
      _titleController.text = widget.existingReport!.title;
      _descriptionController.text = widget.existingReport!.description;
      _selectedCategory = widget.existingReport!.category;
      _selectedLocation = widget.existingReport!.location;
      _locationAddress = widget.existingReport!.locationAddress;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _selectedLocation = LatLng(position.latitude, position.longitude);

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationAddress = '${place.street}, ${place.locality}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as LatLng;
        _locationAddress = result['address'] as String;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final reportService = Provider.of<ReportService>(context, listen: false);

      if (authService.currentUser == null) {
        throw Exception('User not logged in');
      }

      final report = Report(
        id: widget.existingReport?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        photoUrls: widget.existingReport?.photoUrls ?? [],
        location: _selectedLocation!,
        locationAddress: _locationAddress,
        userId: authService.currentUser!.uid,
        userName: authService.currentUser!.displayName ?? 'Anonymous',
        userPhotoUrl: authService.currentUser!.photoURL,
        createdAt: widget.existingReport?.createdAt ?? DateTime.now(),
        status: widget.existingReport?.status ?? ReportStatus.pending,
      );

      if (widget.existingReport != null) {
        await reportService.updateReport(
          widget.existingReport!.id!,
          report,
          _images.isNotEmpty ? _images : null,
        );
      } else {
        await reportService.createReport(report, _images);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReport != null
                  ? 'Report updated successfully'
                  : 'Report submitted successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingReport != null ? 'Edit Report' : 'Report a Problem',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Pothole on Main Street',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide more details here...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<ReportCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: ReportCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Photos Section
            Text('Add Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Existing photos (for edit mode)
            if (widget.existingReport?.photoUrls.isNotEmpty ?? false)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.existingReport!.photoUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageFromString(
                            src: widget.existingReport!.photoUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                    );
                  },
                ),
              ),

            // New photos
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _images[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() => _images.removeAt(index));
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(24, 24),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Media'),
            ),
            const SizedBox(height: 24),

            // Location Section
            Text(
              'Pinpoint the Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.location_on),
              label: Text(
                _locationAddress.isEmpty ? 'Select Location' : _locationAddress,
              ),
            ),

            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton(
              onPressed: _isLoading ? null : _submitReport,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.existingReport != null
                          ? 'Update Report'
                          : 'Submit Report',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadHazard:
        return 'Road Hazard';
      case ReportCategory.streetlight:
        return 'Streetlight';
      case ReportCategory.graffiti:
        return 'Graffiti';
      case ReportCategory.lostPet:
        return 'Lost Pet';
      case ReportCategory.foundPet:
        return 'Found Pet';
      case ReportCategory.parking:
        return 'Parking Issue';
      case ReportCategory.noise:
        return 'Noise Complaint';
      case ReportCategory.waste:
        return 'Waste Management';
      case ReportCategory.other:
        return 'Other';
    }
  }
}
