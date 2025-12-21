import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
            const Text("Help & Support", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Need Help?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're here to assist you",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Contact Support Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact Support",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _contactItem(
                      context,
                      icon: Icons.email,
                      title: "Email Support",
                      subtitle: "support@restro.com",
                      onTap: () => _launchEmail("support@restro.com"),
                    ),
                    const SizedBox(height: 16),
                    _contactItem(
                      context,
                      icon: Icons.phone,
                      title: "Phone Support",
                      subtitle: "+91 9876543210",
                      onTap: () => _launchPhone("+919876543210"),
                    ),
                    const SizedBox(height: 16),
                    _contactItem(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: "Live Chat",
                      subtitle: "Available 24/7",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Live chat feature coming soon!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _faqItem(
                      question: "How do I assign a task?",
                      answer:
                          "Go to the Assign tab in the Manager Dashboard, select an SOP, choose a staff member, set the due date, and click 'Assign Task'.",
                    ),
                    _faqItem(
                      question: "How do I verify tasks?",
                      answer:
                          "Navigate to the Verify tab to see all tasks pending verification. Review the task details and photos, then approve or reject with a reason.",
                    ),
                    _faqItem(
                      question: "How do I create an SOP?",
                      answer:
                          "Go to the SOP tab, fill in the title, description, steps, frequency, and other details, then save. The SOP will be available for task assignment.",
                    ),
                    _faqItem(
                      question: "What happens if a task is rejected?",
                      answer:
                          "When a task is rejected, it is automatically re-assigned to the staff member with the rejection reason. The staff member can then complete it again.",
                    ),
                    _faqItem(
                      question: "How do I upload photos for tasks?",
                      answer:
                          "When starting a task that requires photo evidence, tap the camera icon to capture or select photos from your gallery.",
                    ),
                    _faqItem(
                      question: "Can I change my password?",
                      answer:
                          "Yes, go to your Profile screen and tap on 'Change Password'. Enter your current password and new password to update it.",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Quick Tips Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Tips",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _tipItem(
                        "✓ Complete tasks before the due date to maintain compliance"),
                    _tipItem("✓ Upload clear photos as evidence when required"),
                    _tipItem("✓ Check your dashboard regularly for new tasks"),
                    _tipItem(
                        "✓ Review task details and SOP steps before starting"),
                    _tipItem("✓ Contact support if you encounter any issues"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    // Show email in a dialog or snackbar
    // In a real app, you would use url_launcher package
    // For now, show a message
    // You can add url_launcher package later: url_launcher: ^6.3.1
  }

  Future<void> _launchPhone(String phone) async {
    // Show phone in a dialog or snackbar
    // In a real app, you would use url_launcher package
    // For now, show a message
    // You can add url_launcher package later: url_launcher: ^6.3.1
  }
}
