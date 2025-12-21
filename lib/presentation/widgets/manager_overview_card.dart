import 'package:flutter/material.dart';

class ManagerOverviewCard extends StatelessWidget {
  final int completedToday;
  final int pendingTasks;
  final int verificationPending;

  const ManagerOverviewCard({
    super.key,
    required this.completedToday,
    required this.pendingTasks,
    required this.verificationPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  Icons.check_circle,
                  "Completed Today",
                  completedToday,
                  Colors.green,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _buildItem(
                  Icons.pending,
                  "Pending Tasks",
                  pendingTasks,
                  Colors.orange,
                ),
              ),
            ],
          ),
          _horizontalDivider(),
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  Icons.verified_user,
                  "Verification Pending",
                  verificationPending,
                  Colors.blue,
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space for alignment
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Item UI
  Widget _buildItem(IconData icon, String title, int count, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 26, color: color),
        ),
        const SizedBox(height: 8),
        // Count
        Text(
          "$count",
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 🔹 Vertical divider
  Widget _verticalDivider() {
    return Container(
      width: 2,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.withOpacity(0.2),
    );
  }

  // 🔹 Horizontal divider
  Widget _horizontalDivider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.grey.withOpacity(0.2),
    );
  }
}
