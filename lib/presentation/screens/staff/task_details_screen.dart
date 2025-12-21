import 'package:flutter/material.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  SOPModel? _sop;
  bool _isLoadingSOP = true;

  @override
  void initState() {
    super.initState();
    _loadSOP();
  }

  Future<void> _loadSOP() async {
    if (widget.task.sopid.isNotEmpty) {
      try {
        final sop = await _firestoreService.getSOPById(widget.task.sopid);
        if (mounted) {
          setState(() {
            _sop = sop;
            _isLoadingSOP = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSOP = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingSOP = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String _formatDate(DateTime? date) {
      if (date == null) return 'Not set';
      return "${date.day}/${date.month}/${date.year}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(color: AppTheme.kAccentColor),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          /// --- TOP IMAGE ---
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Image.asset(
              "assets/images/clean_kitchen.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// --- SLIDING DETAILS CONTAINER ---
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Category + Priority Chip Row
                      const Row(
                        children: [
                          // Chip(
                          //   label: Text(task.category),
                          //   backgroundColor: Colors.blue.shade50,
                          // ),
                          SizedBox(width: 10),
                          // Chip(
                          //   label: Text("Priority: ${task.priority}"),
                          //   backgroundColor: Colors.red.shade50,
                          // ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _chip(
                            icon: Icons.repeat,
                            label:
                                "Frequency: ${widget.task.frequency.toString().split('.').last}",
                            color: Colors.blue.shade50,
                            textColor: Colors.blue.shade900,
                          ),
                          _chip(
                            icon: Icons.date_range,
                            label:
                                "Created: ${_formatDate(widget.task.createdAt)}",
                            color: Colors.green.shade50,
                            textColor: Colors.green.shade900,
                          ),
                          if (_sop != null)
                            _chip(
                              icon: Icons.rule,
                              label: "SOP: ${_sop!.title}",
                              color: Colors.purple.shade50,
                              textColor: Colors.purple.shade900,
                            ),
                          _chip(
                            icon: Icons.photo_camera_back_outlined,
                            label:
                                "Photo required: ${_sop?.requiresPhoto == true ? 'Yes' : 'No'}",
                            color: Colors.orange.shade50,
                            textColor: Colors.orange.shade900,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // /// Assigned To
                      // _infoTile(
                      //   icon: Icons.person,
                      //   title: "Assigned To",
                      //   value: widget.task.assignedTo,
                      // ),

                      // const SizedBox(height: 10),

                      // /// Assigned By
                      // _infoTile(
                      //   icon: Icons.badge_outlined,
                      //   title: "Assigned By",
                      //   value: widget.task.assignedBy,
                      // ),

                      // const SizedBox(height: 10),

                      /// Due Date
                      if (widget.task.dueDate != null)
                        _infoTile(
                          icon: Icons.calendar_today,
                          title: "Due Date",
                          value:
                              "${widget.task.dueDate!.day}/${widget.task.dueDate!.month}/${widget.task.dueDate!.year}",
                        ),

                      if (widget.task.dueDate != null)
                        const SizedBox(height: 10),

                      /// Status
                      _infoTile(
                        icon: Icons.flag,
                        title: "Status",
                        value: widget.task.status.toString().split('.').last,
                        color: _getStatusColor(widget.task.status),
                      ),

                      const SizedBox(height: 25),

                      /// Description
                      const Text(
                        "Task Description",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        widget.task.description.isNotEmpty
                            ? widget.task.description
                            : "No description available.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      /// SOP Steps Section
                      if (_isLoadingSOP)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_sop != null && _sop!.steps.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        const Text(
                          "SOP Steps",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._sop!.steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade800,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: 40),

                      /// --- ACTION BUTTONS ---
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, AppRoutes.startTask,
                                    arguments: widget.task);
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Start Task",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          // const SizedBox(width: 15),
                          // Expanded(
                          //   child: ElevatedButton(
                          //     onPressed: () {},
                          //     style: ElevatedButton.styleFrom(
                          //       padding:
                          //           const EdgeInsets.symmetric(vertical: 15),
                          //       backgroundColor: Colors.green,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(14),
                          //       ),
                          //     ),
                          //     child: const Text(
                          //       "Complete Task",
                          //       style: TextStyle(
                          //           fontSize: 16, color: Colors.white),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            },
          ),

          /// --- BACK BUTTON ---
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      {required IconData icon,
      required String label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
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

  /// --- Reusable Info Tile ---
  Widget _infoTile(
      {required IconData icon,
      required String title,
      required String value,
      Color? color}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "$title\n$value",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        if (color != null) CircleAvatar(radius: 8, backgroundColor: color),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last.toLowerCase();
    switch (statusStr) {
      case 'pending':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'verificationpending':
        return Colors.purple;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
