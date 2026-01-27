import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class AnimatedTaskItem extends StatefulWidget {
  final String title;
  final String time;
  final String person;
  final String? status;
  final Color statusColor;
  final int index; // <-- REQUIRED for staggered animation
  final VoidCallback? onTap;
  final String? description;
  final String? frequencyLabel;

  const AnimatedTaskItem(
      {super.key,
      required this.title,
      required this.time,
      required this.person,
      required this.statusColor,
      required this.index,
      this.status,
      this.description,
      this.frequencyLabel,
      this.onTap});

  @override
  State<AnimatedTaskItem> createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<AnimatedTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  String get _statusLabel => (widget.status ?? widget.person).trim();

  String get _subtitleText {
    final s = _statusLabel;
    if (s.isEmpty) return 'Task';
    return '$s Task';
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    // Stagger animation based on item index
    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
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
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subtitleText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: widget.statusColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              color: widget.statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if ((widget.description ?? '').trim().isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.description!.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Task details chips (compact)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCompactChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(widget.time),
                          color: Colors.blue,
                        ),
                        _buildCompactChip(
                          icon: Icons.access_time,
                          label: _formatDateTimeRangeFromString(widget.time),
                          color: Colors.teal,
                        ),
                        _buildCompactChip(
                          icon: Icons.repeat,
                          label: (widget.frequencyLabel ?? '').trim().isEmpty
                              ? 'daily'
                              : widget.frequencyLabel!.trim(),
                          color: Colors.purple,
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

  String _formatTime(String timeString) {
    // Handle time ranges like "Jan 23, 10:00 AM - 11:00 AM"
    if (timeString.contains('-')) {
      final parts = timeString.split('-');
      if (parts.length >= 2) {
        final startTime = parts[0].trim();
        final endTime = parts[1].trim();

        // Extract time from start (e.g., "Jan 23, 10:00 AM" -> "10:00 AM")
        final startParts = startTime.split(' ');
        final startFormatted = startParts.length >= 2
            ? '${startParts[startParts.length - 2]} ${startParts.last}'
            : startTime;

        // Extract time from end (e.g., "11:00 AM")
        final endParts = endTime.split(' ');
        final endFormatted = endParts.length >= 2
            ? '${endParts[endParts.length - 2]} ${endParts.last}'
            : endTime;

        return '$startFormatted - $endFormatted';
      }
    } else if (timeString.contains(',')) {
      // Handle single time like "Jan 23, 10:00 AM"
      final parts = timeString.split(' ');
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]} ${parts.last}';
      }
    }
    return timeString;
  }

  String _formatDate(String timeString) {
    // Extract date from time string like "Jan 20, 9:00 PM - 9:30 PM"
    if (!timeString.contains(',')) return 'No date';

    // Example tokens: [Jan, 20,, 9:00, PM, -, 9:30, PM]
    final parts = timeString.split(' ');
    if (parts.length < 2) return 'No date';

    final month = parts[0].trim();
    final day = parts[1].replaceAll(',', '').trim();
    if (month.isEmpty || day.isEmpty) return 'No date';
    return '$month $day';
  }

  String _formatDateTimeRangeFromString(String timeString) {
    // Input examples:
    // - "Jan 20, 9:00 PM - 9:30 PM"
    // - "Jan 20, 9:00 PM" (fallback)
    final datePart = _formatDate(timeString);

    if (timeString.contains('-')) {
      final parts = timeString.split('-');
      if (parts.length >= 2) {
        final startTime = _formatTime(parts[0].trim());
        final endTime = _formatTime(parts[1].trim());
        return '$datePart, $startTime - $endTime';
      }
    }

    final singleTime = _formatTime(timeString);
    return '$datePart, $singleTime';
  }

  Widget _buildCompactChip({
    required IconData icon,
    required String label,
    required Color color,
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
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    final status = widget.status?.toLowerCase() ?? widget.person.toLowerCase();
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.play_arrow_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'late':
        return Icons.access_time;
      case 'verification pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      case 'future':
        return Icons.schedule;
      default:
        return Icons.task_alt;
    }
  }
}
