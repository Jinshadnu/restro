import 'package:flutter/material.dart';
import 'package:restro/domain/entities/task_entity.dart';

class CompletedTaskModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final String completedBy;
  final Color statusColor;
  final TaskFrequency frequency;

  CompletedTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.completedBy,
    required this.statusColor,
    required this.frequency,
  });
}
