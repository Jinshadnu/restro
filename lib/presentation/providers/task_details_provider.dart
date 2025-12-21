import 'package:flutter/material.dart';

class TaskDetailsProvider extends ChangeNotifier {
  String title;
  String description;
  String assignedTo;
  String status;
  String deadline;
  List<String> activity;

  TaskDetailsProvider({
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.status,
    required this.deadline,
    required this.activity,
  });

  void updateStatus(String newStatus) {
    status = newStatus;
    activity.add("Status changed to $newStatus");
    notifyListeners();
  }
}