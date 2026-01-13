import 'package:flutter/material.dart';

class AnimatedTaskItem extends StatefulWidget {
  final String title;
  final String time;
  final String person;
  final String? status;
  final Color statusColor;
  final int index; // <-- REQUIRED for staggered animation
  final VoidCallback? onTap;

  const AnimatedTaskItem(
      {super.key,
      required this.title,
      required this.time,
      required this.person,
      required this.statusColor,
      required this.index,
      this.status,
      this.onTap});

  @override
  State<AnimatedTaskItem> createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<AnimatedTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

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
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),

              // LEFT BORDER
              border: Border(
                left: BorderSide(
                  color: widget.statusColor,
                  width: 5,
                ),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                // Status Dot
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 14),

                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Person Name
                Text(
                  widget.person,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // NOTE: Keeping the previous commented navigation block below as-is.
        // (Do not delete comments per project rules.)
        //
        // onTap: () {
        // final task = TaskModel(
        //   title: widget.title,
        //   time: widget.time,
        //   assignedTo: widget.person,
        //   statusColor: widget.statusColor,
        //   priority: "Medium",   // add if your UI has priority
        //   category: "General",  // modify as you need
        // );

        // Navigator.pushNamed(
        //   context,
        //   AppRoutes.taskDetails,
        //   arguments: task,
        // );
      ),
    );
  }
}
