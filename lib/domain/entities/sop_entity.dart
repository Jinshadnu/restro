import 'package:restro/domain/entities/task_entity.dart';

class SOPEntity {
  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final TaskFrequency frequency;
  final bool requiresPhoto;
  final bool isCritical; // For owner alerts
  final String? criticalThreshold; // e.g., "temperature > -18"
  final DateTime createdAt;
  final DateTime? updatedAt;

  SOPEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.frequency,
    required this.requiresPhoto,
    this.isCritical = false,
    this.criticalThreshold,
    required this.createdAt,
    this.updatedAt,
  });
}