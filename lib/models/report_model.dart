import 'package:latlong2/latlong.dart';

enum ReportStatus {
  pending,
  approved,
  inProgress,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ReportCategory {
  roadHazard,
  streetlight,
  graffiti,
  lostPet,
  foundPet,
  parking,
  noise,
  waste,
  other;

  String get displayName {
    switch (this) {
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

class Report {
  final String? id;
  final String title;
  final String description;
  final ReportCategory category;
  final List<String> photoUrls;
  final LatLng location;
  final String locationAddress;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ReportStatus status;
  final int likes;
  final int comments;
  final List<String> likedBy;

  const Report({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.photoUrls,
    required this.location,
    required this.locationAddress,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.createdAt,
    this.updatedAt,
    this.status = ReportStatus.pending,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'photoUrls': photoUrls,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'locationAddress': locationAddress,
      'userId': userId,
      'userName': userName,
      if (userPhotoUrl != null) 'userPhotoUrl': userPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'status': status.name,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    final categoryName = map['category'] as String?;
    final statusName = map['status'] as String?;

    return Report(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: categoryName != null
          ? ReportCategory.values.firstWhere(
              (e) => e.name == categoryName,
              orElse: () => ReportCategory.other,
            )
          : ReportCategory.other,
      photoUrls: (map['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      location: LatLng(
        (map['latitude'] as num?)?.toDouble() ?? 0.0,
        (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      locationAddress: map['locationAddress'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      status: statusName != null
          ? ReportStatus.values.firstWhere(
              (e) => e.name == statusName,
              orElse: () => ReportStatus.pending,
            )
          : ReportStatus.pending,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as num?)?.toInt() ?? 0,
      likedBy: (map['likedBy'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Report copyWith({
    String? id,
    String? title,
    String? description,
    ReportCategory? category,
    List<String>? photoUrls,
    LatLng? location,
    String? locationAddress,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReportStatus? status,
    int? likes,
    int? comments,
    List<String>? likedBy,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  String getCategoryDisplayName() => category.displayName;

  String getStatusDisplayName() => status.displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Report && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
