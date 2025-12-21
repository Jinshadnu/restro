class TaskAssignModel {
  final String id;
  final String staffId;
  final String staffName;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;

  // New Fields
  final String sopTitle;
  final String taskType; // Daily or Monthly
  final bool requireEvidence; // Photo proof needed or not

  TaskAssignModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.sopTitle,
    required this.taskType,
    required this.requireEvidence,
  });

  // Convert to Map (Useful for Provider, Firestore, or SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'sopTitle': sopTitle,
      'taskType': taskType,
      'requireEvidence': requireEvidence,
    };
  }

  // Convert from Map
  factory TaskAssignModel.fromMap(Map<String, dynamic> map) {
    return TaskAssignModel(
      id: map['id'],
      staffId: map['staffId'],
      staffName: map['staffName'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: map['priority'],
      sopTitle: map['sopTitle'],
      taskType: map['taskType'],
      requireEvidence: map['requireEvidence'],
    );
  }
}