enum TaskStatus {
  pending,
  inProgress,
  completed,
  verificationPending,
  approved,
  rejected
}

enum TaskFrequency { daily, weekly, monthly }

class TaskEntity {
  final String id;
  final String title;
  final String description;
  final String sopid;
  final String assignedTo; // Staff ID
  final String assignedBy; // Manager ID
  final TaskStatus status;
  final TaskFrequency frequency;
  final DateTime? plannedStartAt;
  final DateTime? plannedEndAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? photoUrl;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final bool requiresPhoto;
  final bool isLate;
  final double? reward;

  TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.sopid,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.frequency,
    this.plannedStartAt,
    this.plannedEndAt,
    this.dueDate,
    this.completedAt,
    this.photoUrl,
    this.rejectionReason,
    required this.createdAt,
    this.verifiedAt,
    this.requiresPhoto = false,
    this.isLate = false,
    this.reward,
  });
}
