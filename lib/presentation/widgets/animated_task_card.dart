import 'package:flutter/material.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/utils/theme/theme.dart';

class AnimatedTaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.index,
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

  Color getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return AppTheme.primaryRed;
      case "Medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final priorityColor = getPriorityColor(widget.task.priority);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),

          /// ***********************
          /// LEFT COLOR BORDER ADDED
          /// ***********************
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // border: Border(
            //   left: BorderSide(
            //     color: priorityColor,
            //     width: 6,
            //   ),
            // ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ROW: Icon + Title + Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Circular Icon (gradient)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt, color: Colors.white),
                  ),

                  const SizedBox(width: 16),

                  /// Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.task.description.isNotEmpty)
                          Text(
                            widget.task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chip(
                              icon: Icons.calendar_month,
                              label: widget.task.dueDate != null
                                  ? _formatDate(widget.task.dueDate!)
                                  : 'No deadline',
                              color: Colors.blue.shade50,
                              textColor: Colors.blue.shade800,
                            ),
                            _chip(
                              icon: Icons.repeat,
                              label: widget.task.frequency
                                  .toString()
                                  .split('.')
                                  .last,
                              color: Colors.purple.shade50,
                              textColor: Colors.purple.shade800,
                            ),
                            _chip(
                              icon: Icons.flag,
                              label:
                                  widget.task.status.toString().split('.').last,
                              color: Colors.orange.shade50,
                              textColor: Colors.orange.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // const Divider(),
              //
              // /// Start Task Button row
              // Row(
              //   children: [
              //     Icon(
              //       Icons.person_outline,
              //       size: 19,
              //       color: Colors.grey.shade600,
              //     ),
              //     const SizedBox(width: 6),
              //     Expanded(
              //       child: Text(
              //         "Assigned by: ${widget.task.assignedBy}",
              //         overflow: TextOverflow.ellipsis,
              //         style: TextStyle(
              //           fontSize: 14,
              //           color: Colors.grey.shade700,
              //         ),
              //       ),
              //     ),
              //     // const SizedBox(width: 8),
              //     // GestureDetector(
              //     //   onTap: () {
              //     //     ScaffoldMessenger.of(context).showSnackBar(
              //     //       SnackBar(
              //     //           content:
              //     //               Text("Task Started: ${widget.task.title}")),
              //     //     );
              //     //   },
              //     //   child: Container(
              //     //     padding: const EdgeInsets.symmetric(
              //     //         horizontal: 22, vertical: 5),
              //     //     decoration: BoxDecoration(
              //     //       gradient: const LinearGradient(
              //     //         colors: [
              //     //           AppTheme.primaryColor,
              //     //           AppTheme.primaryColor
              //     //         ],
              //     //         begin: Alignment.topLeft,
              //     //         end: Alignment.bottomRight,
              //     //       ),
              //     //       borderRadius: BorderRadius.circular(30),
              //     //     ),
              //     //     child: const Text(
              //     //       "Start Task",
              //     //       style: TextStyle(
              //     //         color: Colors.white,
              //     //         fontWeight: FontWeight.w700,
              //     //         fontSize: 14,
              //     //       ),
              //     //     ),
              //     //   ),
              //     // )
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _chip(
      {required IconData icon,
      required String label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
