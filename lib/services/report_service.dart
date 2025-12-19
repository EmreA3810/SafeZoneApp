import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/report_model.dart';
import 'image_utils.dart';

class ReportService extends ChangeNotifier {
  static const String _reportsPath = 'reports';
  static const String _usersPath = 'users';
  static const String _reportsSubmittedKey = 'reportsSubmitted';

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all reports
  Future<void> fetchReports() async {
    try {
      _setLoading(true);

      final snap = await _database.ref().child(_reportsPath).get();

      if (!snap.exists || snap.value == null) {
        _reports = [];
      } else {
        final data = snap.value as Map<dynamic, dynamic>;
        final list = <Report>[];
        data.forEach((key, value) {
          try {
            final map = Map<String, dynamic>.from(value as Map);
            list.add(Report.fromMap(key.toString(), map));
          } catch (e) {
            if (kDebugMode) print('Error parsing report entry: $e');
          }
        });

        // Sort by createdAt descending
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _reports = list;
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Error fetching reports: $e');
      }
      rethrow;
    }
  }

  // Fetch user's reports
  Future<List<Report>> fetchUserReports(String userId) async {
    try {
      final snap = await _database.ref().child(_reportsPath).get();
      final reports = <Report>[];
      if (!snap.exists || snap.value == null) return reports;

      final data = snap.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          if (map['userId'] == userId) {
            reports.add(Report.fromMap(key.toString(), map));
          }
        } catch (e) {
          if (kDebugMode) print('Error parsing report entry: $e');
        }
      });

      // Sort by createdAt manually
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user reports: $e');
      }
      rethrow;
    }
  }

  // Compress images and return base64 strings to store in Realtime Database
  Future<List<String>> uploadImagesAsBase64(
    List<File> images, {
    int targetWidth = 800,
    int quality = 70,
    int maxImages = 3,
  }) async {
    List<String> imageBase64 = [];

    final limit = images.length < maxImages ? images.length : maxImages;

    for (int i = 0; i < limit; i++) {
      try {
        final base64 = await ImageUtils.compressFileToBase64(
          images[i],
          targetWidth: targetWidth,
          quality: quality,
        );
        imageBase64.add(base64);
      } catch (e) {
        if (kDebugMode) {
          print('Error compressing/uploading image as base64: $e');
        }
      }
    }

    return imageBase64;
  }

  // Create a new report
  Future<void> createReport(Report report, List<File> images) async {
    try {
      // Create a new report node to get a key
      final ref = _database.ref().child(_reportsPath).push();

      // Prepare base map and set it (photoUrls may be empty for now)
      final map = report.toMap();
      await ref.set(map);

      // Upload images if any (compress to base64)
      if (images.isNotEmpty) {
        final imageBase64 = await uploadImagesAsBase64(images);
        if (imageBase64.isNotEmpty) {
          await ref.update({'photoUrls': imageBase64});
        }
      }

      // Update user's report count (best-effort read-modify-write; no transaction)
      await _updateUserReportCount(report.userId, 1);

      // Refresh reports
      await fetchReports();
    } catch (e) {
      if (kDebugMode) {
        print('Error creating report: $e');
      }
      rethrow;
    }
  }

  // Update a report
  Future<void> updateReport(
    String reportId,
    Report report,
    List<File>? newImages, {
    List<String>? removedPhotoUrls,
  }) async {
    try {
      final ref = _database.ref().child(_reportsPath).child(reportId);

      Map<String, Object?> updateData = {
        'title': report.title,
        'description': report.description,
        'category': report.category.name,
        'locationAddress': report.locationAddress,
        'latitude': report.location.latitude,
        'longitude': report.location.longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Read existing photoUrls (we may need to remove items or append new uploads)
      final snap = await ref.get();
      List<dynamic> existing = [];
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        existing = List<dynamic>.from(map['photoUrls'] ?? []);
      }

      // Remove any requested photo URLs
      if (removedPhotoUrls != null && removedPhotoUrls.isNotEmpty) {
        existing.removeWhere((e) => removedPhotoUrls.contains(e));
      }

      // Upload new images (as base64) and append
      if (newImages != null && newImages.isNotEmpty) {
        final imageBase64 = await uploadImagesAsBase64(newImages);
        if (imageBase64.isNotEmpty) {
          existing = [...existing, ...imageBase64];
        }
      }

      updateData['photoUrls'] = existing;

      await ref.update(updateData);
      await fetchReports();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating report: $e');
      }
      rethrow;
    }
  }

  // Delete a report
  Future<void> deleteReport(String reportId, String userId) async {
    try {
      final ref = _database.ref().child(_reportsPath).child(reportId);
      await ref.remove();

      await _updateUserReportCount(userId, -1);

      await fetchReports();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting report: $e');
      }
      rethrow;
    }
  }

  // Toggle like on a report
  Future<void> toggleLike(String reportId, String userId) async {
    try {
      final ref = _database.ref().child(_reportsPath).child(reportId);
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.value as Map<dynamic, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      int likes = data['likes'] is int
          ? data['likes'] as int
          : (int.tryParse('${data['likes']}') ?? 0);

      if (likedBy.contains(userId)) {
        // Unlike
        likedBy.remove(userId);
        likes = likes - 1 < 0 ? 0 : likes - 1;
      } else {
        likedBy.add(userId);
        likes = likes + 1;
      }

      await ref.update({'likes': likes, 'likedBy': likedBy});

      await fetchReports();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling like: $e');
      }
      rethrow;
    }
  }

  // Update report status (admin function)
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      final ref = _database.ref().child(_reportsPath).child(reportId);
      await ref.update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchReports();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating report status: $e');
      }
      rethrow;
    }
  }

  Future<void> _updateUserReportCount(String userId, int delta) async {
    // RTDB update
    try {
      final userRef = _database.ref().child(_usersPath).child(userId);
      final snap = await userRef.get();
      int current = 0;
      if (snap.exists && snap.value is Map) {
        current = _parseReportsCount(
          Map<String, dynamic>.from(snap.value as Map),
        );
      }
      final next = (current + delta).clamp(0, 1 << 31);
      await userRef.set({_reportsSubmittedKey: next});

      // Mirror to Firestore
      await _firestore.collection(_usersPath).doc(userId).set({
        _reportsSubmittedKey: next,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Warning: failed to update report count: $e');
      }
    }
  }

  int _parseReportsCount(Map<String, dynamic> data) {
    final value = data[_reportsSubmittedKey];
    if (value is int) return value;
    if (value != null) return int.tryParse('$value') ?? 0;
    return 0;
  }
}
