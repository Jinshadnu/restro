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
      final users = await _firestoreService.getAllUsers();
      setState(() {
        staffList = users;
        filteredList = users;
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
            const Text("Manage Staff", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          // Navigate to add staff screen
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ------------------ SEARCH BAR -----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: searchStaff,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search staff...",
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ------------------ STAFF LIST -----------------
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No staff found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStaff,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final staff = filteredList[index];

                            return _staffCard(
                              name: staff["name"]?.toString() ?? 'Unknown',
                              email: staff["email"]?.toString() ?? '',
                              phone: staff["phone"]?.toString() ?? '',
                              role: staff["role"]?.toString() ?? '',
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

  // ================================================================
  //                       STAFF CARD WIDGET
  // ================================================================
  Widget _staffCard({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String avatar,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage(avatar),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 13)),
            Text("Phone: $phone", style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),

            // ROLE BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getRoleColor(role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == "edit") onEdit();
            if (value == "delete") onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: "edit", child: Text("Edit")),
            const PopupMenuItem(
              value: "delete",
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  // Get dynamic badge color
  Color _getRoleColor(String role) {
    switch (role) {
      case "admin":
        return Colors.red;
      case "manager":
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  // ================================================================
  //                  DELETE CONFIRMATION POPUP
  // ================================================================
  void _showDeleteDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Staff"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
