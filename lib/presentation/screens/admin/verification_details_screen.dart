import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class VerificationDetailsScreen extends StatefulWidget {
  final String taskId;
  final String staff;
  final String task;
  final String sop;
  final String date;
  final List<String> images;
  final bool isVerified;

  // NEW FIELDS
  final DateTime dueTime;
  final DateTime completedTime;

  const VerificationDetailsScreen({
    super.key,
    required this.taskId,
    required this.staff,
    required this.task,
    required this.sop,
    required this.date,
    required this.images,
    required this.isVerified,

    /// NEW VALUES REQUIRED
    required this.dueTime,
    required this.completedTime,
  });

  @override
  State<VerificationDetailsScreen> createState() =>
      _VerificationDetailsScreenState();
}

class _VerificationDetailsScreenState extends State<VerificationDetailsScreen> {
  final TextEditingController _remarksCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<TaskProvider>(context, listen: false)
          .verifyTask(widget.taskId, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task approved'),
          backgroundColor: AppTheme.success,
        ),
      );
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reject(String reason) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<TaskProvider>(context, listen: false).verifyTask(
        widget.taskId,
        false,
        rejectionReason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task rejected'),
          backgroundColor: AppTheme.warning,
        ),
      );
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Check if task was completed on time
    final completedLocal = widget.completedTime.toLocal();
    final dueLocal = widget.dueTime.toLocal();
    final bool isOnTime = completedLocal.isBefore(dueLocal) ||
        completedLocal.isAtSameMomentAs(dueLocal);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Verification Details",
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -------------- DETAILS CARD --------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Task Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _detailRow("Staff Name", widget.staff),
                  _detailRow("Task Title", widget.task),
                  _detailRow("SOP", widget.sop),
                  _detailRow("Submitted On", widget.date),

                  /// 💠 NEW FIELD - COMPLETED TIME
                  _detailRow(
                    "Completed Time",
                    "${completedLocal.hour}:${completedLocal.minute.toString().padLeft(2, '0')} "
                        "${completedLocal.day}-${completedLocal.month}-${completedLocal.year}",
                  ),

                  /// 💠 NEW FIELD - DUE TIME
                  _detailRow(
                    "Due Time",
                    "${dueLocal.hour}:${dueLocal.minute.toString().padLeft(2, '0')} "
                        "${dueLocal.day}-${dueLocal.month}-${dueLocal.year}",
                  ),

                  const SizedBox(height: 6),

                  /// 💠 NEW FIELD - ON TIME STATUS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Task Status",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnTime
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOnTime ? "On Time" : "Late",
                          style: TextStyle(
                            color: isOnTime ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ----------------------------------------------------
            /// IMAGE LIST (same as before)
            /// ----------------------------------------------------
            const Text("Photo Evidence",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (widget.images.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No photos submitted.'),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = widget.images[index];
                    return GestureDetector(
                      onTap: () => _openImage(context, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 140,
                              height: 140,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            /// -----------------------------------------------
            /// Remarks and Buttons (same as before)
            /// -----------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: TextFormField(
                controller: _remarksCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Remarks (optional)",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _approve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Approve",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _showRejectReasonPopup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Reject",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  /// ---------------- DETAIL ROW ----------------
  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Image viewer & dialogs remain unchanged)
  void _openImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  void _showRejectReasonPopup(BuildContext context) {
    final TextEditingController reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Reject Task"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Reason for rejection",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter a reason";
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _reject(reasonCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
