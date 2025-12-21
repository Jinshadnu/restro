import 'package:flutter/material.dart';

class StatusOverviewCard extends StatelessWidget {
  final int total;
  final int pending;
  final int completed;
  final int cancelled;

  const StatusOverviewCard({
    super.key,
    required this.total,
    required this.pending,
    required this.completed,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ White card
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
              Expanded(child: _buildItem(Icons.list_alt, "Total", total, Colors.deepPurple)),
              _verticalDivider(),
              Expanded(child: _buildItem(Icons.timelapse, "Pending", pending, Colors.orange)),
            ],
          ),

          _horizontalDivider(),

          Row(
            children: [
              Expanded(child: _buildItem(Icons.check_circle, "Completed", completed, Colors.green)),
              _verticalDivider(),
              Expanded(child: _buildItem(Icons.cancel, "Cancelled", cancelled, Colors.red)),
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

        const SizedBox(height: 4),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
        ),

        // Count
        Text(
          "$count",
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  // 🔹 Vertical divider
  Widget _verticalDivider() {
    return Container(
      width: 2,
      height: 70,
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