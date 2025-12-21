import 'package:flutter/material.dart';
import 'package:restro/data/models/completed_task_model.dart';

class CompletedTaskCard extends StatelessWidget {
  final CompletedTaskModel task;

  const CompletedTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// -----------------------
          /// 🔥 Title Row
          /// -----------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
              ),

              Icon(Icons.verified_rounded,
                  size: 26, color: task.statusColor.withOpacity(0.9)),
            ],
          ),

          const SizedBox(height: 12),

          /// -----------------------
          /// 🕒 Time Row
          /// -----------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_filled_rounded,
                    size: 16, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Text(
                task.time,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 14),

          /// -----------------------
          /// 👤 Completed By + Status
          /// -----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // /// Completed by user
              // Row(
              //   children: [
              //     CircleAvatar(
              //       radius: 14,
              //       backgroundColor: Colors.green.withOpacity(0.15),
              //       child:
              //       const Icon(Icons.person, size: 16, color: Colors.green),
              //     ),
              //     const SizedBox(width: 8),
              //     Text(
              //       "By ${task.completedBy}",
              //       style: const TextStyle(
              //         fontSize: 15,
              //         color: Colors.black87,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     )
              //   ],
              // ),

              /// Completed status pill
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: task.statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Completed",
                  style: TextStyle(
                    color: task.statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}