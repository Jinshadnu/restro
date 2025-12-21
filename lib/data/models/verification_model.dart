class VerificationItem {
  final String id;
  final String staffName;
  final String taskTitle;
  final String sopTitle;
  final String submittedDate;
  final String imageUrl;
  final bool isVerified;

  VerificationItem({
    required this.id,
    required this.staffName,
    required this.taskTitle,
    required this.sopTitle,
    required this.submittedDate,
    required this.imageUrl,
    this.isVerified = false,
  });
}