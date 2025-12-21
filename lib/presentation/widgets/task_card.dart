import 'package:flutter/material.dart';
import 'package:restro/data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// -----------------------
          /// Task Title + Status Icon
          /// -----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),

              // Icon(
              //   Icons.pending_actions_rounded,
              //   size: 26,
              //   color: task.statusColor.withOpacity(0.9),
              // ),
            ],
          ),

          const SizedBox(height: 12),

          /// -----------------------
          /// Time Row
          /// -----------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              // Text(
              //   task.time,
              //   style: TextStyle(
              //     fontSize: 15,
              //     color: Colors.grey[800],
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(height: 1, color: Colors.black12),

          const SizedBox(height: 14),

          /// -----------------------
          /// Assigned To + Status Pill
          /// -----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// Assigned user row
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.orange.withOpacity(0.15),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    task.assignedTo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              /// Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                // decoration: BoxDecoration(
                //   color: task.statusColor.withOpacity(0.16),
                //   borderRadius: BorderRadius.circular(20),
                // ),
                // child: Text(
                //   "Pending",
                //   style: TextStyle(
                //     color: task.statusColor,
                //     fontSize: 13,
                //     fontWeight: FontWeight.w800,
                //   ),
                // ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}