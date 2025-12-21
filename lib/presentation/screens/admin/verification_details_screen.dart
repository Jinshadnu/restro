import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class VerificationDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final TextEditingController remarksCtrl = TextEditingController();

    /// Check if task was completed on time
    bool isOnTime = completedTime.isBefore(dueTime) ||
        completedTime.isAtSameMomentAs(dueTime);

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

                  _detailRow("Staff Name", staff),
                  _detailRow("Task Title", task),
                  _detailRow("SOP", sop),
                  _detailRow("Submitted On", date),

                  /// 💠 NEW FIELD - COMPLETED TIME
                  _detailRow(
                    "Completed Time",
                    "${completedTime.hour}:${completedTime.minute.toString().padLeft(2, '0')} "
                        "${completedTime.day}-${completedTime.month}-${completedTime.year}",
                  ),

                  /// 💠 NEW FIELD - DUE TIME
                  _detailRow(
                    "Due Time",
                    "${dueTime.hour}:${dueTime.minute.toString().padLeft(2, '0')} "
                        "${dueTime.day}-${dueTime.month}-${dueTime.year}",
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

            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openImage(context, images[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
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
                controller: remarksCtrl,
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
                    onPressed: () => _showApprovedDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Approve",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectReasonPopup(context),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
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

  void _showApprovedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Task Approved"),
        content: const Text("You have approved this task successfully."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
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
                _showRejectedDialog(context, reasonCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showRejectedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Task Rejected"),
        content: Text("Reason: $reason"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
