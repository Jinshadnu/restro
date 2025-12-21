import 'package:restro/domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.sopid,
    required super.assignedTo,
    required super.assignedBy,
    required super.status,
    required super.frequency,
    super.dueDate,
    super.completedAt,
    super.photoUrl,
    super.rejectionReason,
    required super.createdAt,
    super.verifiedAt,
    super.requiresPhoto = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sopid:
          json['sopid'] ?? json['sopId'] ?? '', // Support both sopid and sopId
      assignedTo: json['assignedTo'] ?? '',
      assignedBy: json['assignedBy'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
      frequency: _frequencyFromString(json['frequency'] ?? 'daily'),
      dueDate: _parseDateTime(json['dueDate']),
      completedAt: _parseDateTime(json['completedAt']),
      photoUrl: json['photoUrl'],
      rejectionReason: json['rejectionReason'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      verifiedAt: _parseDateTime(json['verifiedAt']),
      requiresPhoto: json['requiresPhoto'] == true ||
          (json['requiresPhoto'] is String &&
              (json['requiresPhoto'] as String).toLowerCase() == 'true'),
    );
  }

  /// Parse DateTime from Firestore Timestamp, DateTime, or String
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final tsType = value.runtimeType.toString();
    if (tsType == 'Timestamp' || tsType.endsWith('Timestamp')) {
      // Firestore Timestamp support without direct import to avoid circular deps
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

  static TaskStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'verificationpending':
        return TaskStatus.verificationPending;
      case 'approved':
        return TaskStatus.approved;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sopid': sopid, // Use lowercase to match Firestore structure
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'status': status.toString().split('.').last,
      'frequency': frequency.toString().split('.').last,
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'requiresPhoto': requiresPhoto,
    };
  }

  static TaskFrequency _frequencyFromString(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return TaskFrequency.daily;
      case 'weekly':
        return TaskFrequency.weekly;
      case 'monthly':
        return TaskFrequency.monthly;
      default:
        return TaskFrequency.daily;
    }
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      sopid: entity.sopid,
      assignedTo: entity.assignedTo,
      assignedBy: entity.assignedBy,
      status: entity.status,
      frequency: entity.frequency,
      dueDate: entity.dueDate,
      completedAt: entity.completedAt,
      photoUrl: entity.photoUrl,
      rejectionReason: entity.rejectionReason,
      createdAt: entity.createdAt,
      verifiedAt: entity.verifiedAt,
      requiresPhoto: entity.requiresPhoto,
    );
  }
}
