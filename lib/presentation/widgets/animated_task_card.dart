import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/utils/theme/theme.dart';

class AnimatedTaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;
  final VoidCallback? onTap;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.index,
    this.onTap,
  });

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted && !_isDisposed) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  IconData getTaskIcon(String type) {
    switch (type) {
      case "Cleaning":
        return Icons.cleaning_services_rounded;
      case "Kitchen":
        return Icons.restaurant_rounded;
      case "Stock":
        return Icons.inventory_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  bool get _isFuture {
    if (widget.task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(widget.task.dueDate!.year,
        widget.task.dueDate!.month, widget.task.dueDate!.day);
    return taskDate.isAfter(today);
  }

  String _getHumanReadableStatus() {
    switch (widget.task.status) {
      case TaskStatus.completed:
      case TaskStatus.approved:
        return 'Completed';
      case TaskStatus.verificationPending:
        return 'Verification Pending';
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.rejected:
        return 'Rejected';
      default:
        return widget.task.status.toString().split('.').last;
    }
  }

  Color get _statusColor {
    if (_isFuture) return Colors.grey;

    switch (widget.task.status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.verificationPending:
        return Colors.purple;
      case TaskStatus.completed:
      case TaskStatus.approved:
        return Colors.green;
      case TaskStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isFuture ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFuture
                  ? Colors.grey.shade300
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _isFuture
                                      ? Colors.grey.shade600
                                      : AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pending Task',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _isFuture ? 'Future' : 'Pending',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (widget.task.isLate) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppTheme.error.withOpacity(0.18),
                                  ),
                                ),
                                child: const Text(
                                  'Late',
                                  style: TextStyle(
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (widget.task.description.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Description',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.task.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Task details chips (wrap to avoid overflow)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCompactChip(
                          icon: Icons.calendar_today,
                          label: widget.task.dueDate != null
                              ? _formatDate(widget.task.dueDate!)
                              : 'No deadline',
                          color: Colors.blue,
                          maxWidth: 110,
                        ),
                        _buildCompactChip(
                          icon: Icons.access_time,
                          label: widget.task.plannedStartAt != null &&
                                  widget.task.plannedEndAt != null
                              ? _formatDateWithTimeRange(
                                  widget.task.plannedStartAt!,
                                  widget.task.plannedEndAt!,
                                )
                              : (widget.task.dueDate != null
                                  ? _formatDateTime(widget.task.dueDate!)
                                  : 'No time'),
                          color: Colors.teal,
                          maxWidth: 220,
                        ),
                        _buildCompactChip(
                          icon: Icons.repeat,
                          label:
                              widget.task.frequency.toString().split('.').last,
                          color: Colors.purple,
                          maxWidth: 90,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
  }

  String _formatDateWithTimeRange(DateTime startTime, DateTime endTime) {
    final datePart = DateFormat('MMM d').format(startTime.toLocal());
    final startFormatted = DateFormat('h:mm a').format(startTime.toLocal());
    final endFormatted = DateFormat('h:mm a').format(endTime.toLocal());
    return '$datePart, $startFormatted - $endFormatted';
  }

  String _formatTimeRange(DateTime? startTime, DateTime? endTime) {
    if (startTime != null && endTime != null) {
      final startFormatted = DateFormat('h:mm a').format(startTime.toLocal());
      final endFormatted = DateFormat('h:mm a').format(endTime.toLocal());
      return '$startFormatted - $endFormatted';
    } else if (startTime != null) {
      return DateFormat('h:mm a').format(startTime.toLocal());
    }
    return 'No time';
  }

  Widget _buildCompactChip({
    required IconData icon,
    required String label,
    required Color color,
    double maxWidth = 140,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
