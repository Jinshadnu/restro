enum TaskStatus {
  pending,
  inProgress,
  completed,
  verificationPending,
  approved,
  rejected
}

enum TaskFrequency { daily, weekly, monthly }

enum TaskGrade {
  normal,
  critical, // Grade A (Critical) tasks like Egg Pasteurization
}

class TaskEntity {
  final String id;
  final String title;
  final String description;
  final String sopid;
  final String assignedTo; // Staff ID
  final String assignedBy; // Manager ID
  final TaskStatus status;
  final TaskFrequency frequency;
  final TaskGrade grade; // NEW: Critical task grade
  final DateTime? plannedStartAt;
  final DateTime? plannedEndAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? photoUrl;
  final String? rejectionReason;
  final String? rejectionVoiceNoteUrl;
  final String? rejectionMarkedImageUrl;
  final DateTime? rejectedAt;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final bool requiresPhoto;
  final bool isLate;
  final double? reward;

  // NEW: Owner override tracking
  final DateTime? ownerRejectionAt;
  final String? ownerRejectionReason;
  final String? rejectedBy; // Owner ID who rejected

  TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.sopid,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.frequency,
    this.grade = TaskGrade.normal, // NEW: Default to normal
    this.plannedStartAt,
    this.plannedEndAt,
    this.dueDate,
    this.completedAt,
    this.photoUrl,
    this.rejectionReason,
    this.rejectionVoiceNoteUrl,
    this.rejectionMarkedImageUrl,
    this.rejectedAt,
    required this.createdAt,
    this.verifiedAt,
    this.requiresPhoto = false,
    this.isLate = false,
    this.reward,
    this.ownerRejectionAt,
    this.ownerRejectionReason,
    this.rejectedBy,
  });
}
