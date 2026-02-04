import 'package:restro/domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  AttendanceModel({
    required super.id,
    required super.userId,
    super.imageUrl,
    super.imagePath,
    required super.date,
    required super.timestamp,
    super.status,
    super.verifiedBy,
    super.verifiedAt,
    super.rejectionReason,
    super.synced,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'],
      imagePath: json['local_image_path'],
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      timestamp: _parseDateTime(json['timestamp']) ?? DateTime.now(),
      status: _statusFromString(json['status'] ?? 'pending'),
      verifiedBy: json['verifiedBy'],
      verifiedAt: _parseDateTime(json['verifiedAt']),
      rejectionReason: json['rejectionReason'],
      synced: json['synced'] == true,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final tsType = value.runtimeType.toString();
    if (tsType == 'Timestamp' || tsType.endsWith('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static AttendanceStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AttendanceStatus.verified;
      case 'rejected':
        return AttendanceStatus.rejected;
      default:
        return AttendanceStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final statusStr = status.toString().split('.').last;

    return {
      'id': id,
      'userId': userId,
      'staff_id': userId,
      'imageUrl': imageUrl,
      'local_image_path': imagePath,
      'date': date.toIso8601String(),
      'dateStr': dateStr,
      'timestamp': timestamp.toIso8601String(),
      'capturedAt': timestamp.toIso8601String(),
      'status': statusStr,
      'verification_status': statusStr == 'verified'
          ? 'approved'
          : statusStr == 'rejected'
              ? 'rejected'
              : 'pending',
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'synced': synced,
      'sync_status': synced ? 'synced' : 'pending',
    };
  }
}
