import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sop_entity.dart';
import '../../domain/entities/task_entity.dart';

class SOPModel extends SOPEntity {
  SOPModel({
    required super.id,
    required super.title,
    required super.description,
    required super.steps,
    required super.frequency,
    required super.requiresPhoto,
    super.isCritical,
    super.criticalThreshold,
    required super.createdAt,
    super.updatedAt,
  });

  factory SOPModel.fromJson(Map<String, dynamic> json) {
    return SOPModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      steps:
          json['steps'] != null ? List<String>.from(json['steps']) : <String>[],
      frequency: _frequencyFromString(json['frequency'] ?? 'daily'),
      requiresPhoto: json['requiresPhoto'] ?? false,
      isCritical: json['isCritical'] ?? false,
      criticalThreshold: json['criticalThreshold'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to parse DateTime from Firestore Timestamp or String
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // If it's a Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }

    // If it's a String, try to parse it
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'steps': steps,
      'frequency': frequency.toString().split('.').last,
      'requiresPhoto': requiresPhoto,
      'isCritical': isCritical,
      'criticalThreshold': criticalThreshold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SOPModel.fromEntity(SOPEntity entity) {
    return SOPModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      steps: entity.steps,
      frequency: entity.frequency,
      requiresPhoto: entity.requiresPhoto,
      isCritical: entity.isCritical,
      criticalThreshold: entity.criticalThreshold,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
