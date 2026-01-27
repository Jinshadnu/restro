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
    super.grade = TaskGrade.normal, // NEW: Add grade parameter
    super.plannedStartAt,
    super.plannedEndAt,
    super.dueDate,
    super.completedAt,
    super.photoUrl,
    super.rejectionReason,
    super.rejectionVoiceNoteUrl,
    super.rejectionMarkedImageUrl,
    super.rejectedAt,
    required super.createdAt,
    super.verifiedAt,
    super.requiresPhoto = false,
    super.isLate = false,
    super.reward,
    super.ownerRejectionAt,
    super.ownerRejectionReason,
    super.rejectedBy,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawDescription = json['description'] ??
        json['taskDescription'] ??
        json['task_description'] ??
        json['details'] ??
        json['taskDetails'] ??
        '';

    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: rawDescription?.toString() ?? '',
      sopid:
          json['sopid'] ?? json['sopId'] ?? '', // Support both sopid and sopId
      assignedTo: json['assignedTo'] ?? '',
      assignedBy: json['assignedBy'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
      frequency: _frequencyFromString(json['frequency'] ?? 'daily'),
      grade: _gradeFromString(json['grade'] ?? 'normal'), // NEW: Parse grade
      plannedStartAt: _parseDateTime(json['plannedStartAt']),
      plannedEndAt: _parseDateTime(json['plannedEndAt']),
      dueDate: _parseDateTime(json['dueDate']),
      completedAt: _parseDateTime(
        json['completedAt'] ?? json['completed_at'] ?? json['completed_time'],
      ),
      photoUrl: json['photoUrl'],
      rejectionReason: json['rejectionReason'],
      rejectionVoiceNoteUrl: json['rejectionVoiceNoteUrl'],
      rejectionMarkedImageUrl: json['rejectionMarkedImageUrl'],
      rejectedAt: _parseDateTime(
        json['rejectedAt'] ?? json['rejected_at'] ?? json['rejected_time'],
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      verifiedAt: _parseDateTime(
        json['verifiedAt'] ?? json['verified_at'] ?? json['verified_time'],
      ),
      requiresPhoto: json['requiresPhoto'] == true ||
          (json['requiresPhoto'] is String &&
              (json['requiresPhoto'] as String).toLowerCase() == 'true'),
      isLate: json['isLate'] == true ||
          (json['isLate'] is String &&
              (json['isLate'] as String).toLowerCase() == 'true'),
      reward: _parseNum(json['reward'])?.toDouble() ??
          50.0, // Default to 50 if not specified
      ownerRejectionAt: _parseDateTime(
        json['ownerRejectionAt'] ??
            json['owner_rejection_at'] ??
            json['ownerRejectedAt'],
      ),
      ownerRejectionReason: json['ownerRejectionReason'],
      rejectedBy: json['rejectedBy'],
    );
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim());
    }
    return null;
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
    final normalized = status.toLowerCase().replaceAll('_', '');
    switch (normalized) {
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

  static TaskGrade _gradeFromString(String grade) {
    // NEW: Parse grade
    switch (grade.toLowerCase()) {
      case 'critical':
        return TaskGrade.critical;
      case 'normal':
      default:
        return TaskGrade.normal;
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
      'grade': grade.toString().split('.').last, // NEW: Add grade to JSON
      'plannedStartAt': plannedStartAt?.toIso8601String(),
      'plannedEndAt': plannedEndAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'rejectionReason': rejectionReason,
      'rejectionVoiceNoteUrl': rejectionVoiceNoteUrl,
      'rejectionMarkedImageUrl': rejectionMarkedImageUrl,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'requiresPhoto': requiresPhoto,
      'isLate': isLate,
      'reward': reward,
      'ownerRejectionAt': ownerRejectionAt?.toIso8601String(),
      'ownerRejectionReason': ownerRejectionReason,
      'rejectedBy': rejectedBy,
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
      grade: entity.grade, // NEW: Add grade from entity
      plannedStartAt: entity.plannedStartAt,
      plannedEndAt: entity.plannedEndAt,
      dueDate: entity.dueDate,
      completedAt: entity.completedAt,
      photoUrl: entity.photoUrl,
      rejectionReason: entity.rejectionReason,
      rejectionVoiceNoteUrl: entity.rejectionVoiceNoteUrl,
      rejectionMarkedImageUrl: entity.rejectionMarkedImageUrl,
      rejectedAt: entity.rejectedAt,
      createdAt: entity.createdAt,
      verifiedAt: entity.verifiedAt,
      requiresPhoto: entity.requiresPhoto,
      isLate: entity.isLate,
      reward: entity.reward,
      ownerRejectionAt: entity.ownerRejectionAt,
      ownerRejectionReason: entity.ownerRejectionReason,
      rejectedBy: entity.rejectedBy,
    );
  }

  /// Convert TaskModel to TaskEntity
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      sopid: sopid,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      status: status,
      frequency: frequency,
      grade: grade,
      plannedStartAt: plannedStartAt,
      plannedEndAt: plannedEndAt,
      dueDate: dueDate,
      completedAt: completedAt,
      photoUrl: photoUrl,
      rejectionReason: rejectionReason,
      rejectionVoiceNoteUrl: rejectionVoiceNoteUrl,
      rejectionMarkedImageUrl: rejectionMarkedImageUrl,
      rejectedAt: rejectedAt,
      createdAt: createdAt,
      verifiedAt: verifiedAt,
      requiresPhoto: requiresPhoto,
      isLate: isLate,
      reward: reward,
      ownerRejectionAt: ownerRejectionAt,
      ownerRejectionReason: ownerRejectionReason,
      rejectedBy: rejectedBy,
    );
  }
}
