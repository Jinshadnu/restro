enum AttendanceStatus { pending, verified, rejected }

class Attendance {
  final String id;
  final String userId;
  final String? imageUrl; // Firebase Storage URL
  final String? imagePath; // Local path (for offline support)
  final DateTime date;
  final DateTime timestamp;
  final AttendanceStatus status;
  final String? verifiedBy; // Manager ID who verified
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final bool synced;

  Attendance({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.imagePath,
    required this.date,
    required this.timestamp,
    this.status = AttendanceStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.synced = false,
  });
}
