import 'package:flutter/material.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/utils/theme/theme.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> filteredList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await _firestoreService.getAllUsers();
      // Filter to show only staff members (excluding admin, manager, owner)
      setState(() {
        staffList = allUsers.where((user) {
          final role = user["role"]?.toString().toLowerCase() ?? '';
          return role == 'staff';
        }).toList();
        filteredList = staffList;
      });
    } catch (e) {
      print('Error loading staff: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void searchStaff(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = staffList;
      } else {
        filteredList = staffList
            .where((staff) =>
                (staff["name"] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                (staff["email"] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Gradient Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Text(
                      'Manage Staff',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                        width: 40), // Balance the back button for centering
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar integrated in Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: searchStaff,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search staff members...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                      ),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchCtrl.clear();
                                searchStaff('');
                              },
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.grey),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Staff Team',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${filteredList.length} Members",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Staff List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_rounded,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No staff members found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStaff,
                        color: AppTheme.primaryColor,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final staff = filteredList[index];
                            return _enhancedStaffCard(
                              name: staff["name"]?.toString() ?? 'Unknown',
                              email: staff["email"]?.toString() ?? '',
                              phone: staff["phone"]?.toString() ?? '',
                              role: staff["staff_role"]?.toString() ??
                                  staff["role"]?.toString() ??
                                  '',
                              avatar: staff["avatar"]?.toString() ??
                                  "assets/images/avatar.png",
                              onEdit: () {
                                // Navigate to edit staff
                              },
                              onDelete: () {
                                _showDeleteDialog(context,
                                    staff["name"]?.toString() ?? 'Unknown');
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // No longer needed as separate widgets, but keeping helper methods
  // _buildSearchBar and _buildSectionHeader are replaced by inline code for better layout control
  // _staffCard is replaced by _enhancedStaffCard

  Widget _enhancedStaffCard({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String avatar,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final roleColor = _getRoleColor(role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Optional: View details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Ring
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: roleColor.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: AssetImage(avatar),
                        backgroundColor: Colors.grey[200],
                        onBackgroundImageError: (_, __) {
                          // Fallback handled by default icon usually, or use a custom widget
                        },
                        child: avatar == "assets/images/avatar.png"
                            ? Icon(Icons.person,
                                color: Colors.grey[400], size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildRoleBadge(role, roleColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (email.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.email_outlined,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      label: "Edit",
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      label: "Delete",
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onTap: onDelete,
                      isOutlined: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getFormattedRole(role),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get dynamic badge color
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return Colors.red;
      case "manager":
        return Colors.blue;
      case "owner":
        return Colors.purple;
      case "chef":
        return Colors.orange;
      case "waiter":
        return Colors.green;
      case "cleaner":
        return Colors.cyan;
      default:
        return AppTheme.primaryColor;
    }
  }

  // Get formatted role display text
  String _getFormattedRole(String role) {
    switch (role.toLowerCase()) {
      case "chef":
        return "Chef";
      case "waiter":
        return "Waiter";
      case "cleaner":
        return "Cleaner";
      case "staff":
        return "Staff Member";
      default:
        return role.isNotEmpty ? role : "Staff Member";
    }
  }

  // ================================================================
  //                  DELETE CONFIRMATION POPUP
  // ================================================================
  void _showDeleteDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Staff"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$name deleted successfully")),
              );
            },
          ),
        ],
      ),
    );
  }
}
