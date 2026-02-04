import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/datasources/remote/firestore_service.dart';

class ManageStaffRolesScreen extends StatefulWidget {
  const ManageStaffRolesScreen({super.key});

  @override
  State<ManageStaffRolesScreen> createState() => _ManageStaffRolesScreenState();
}

class _ManageStaffRolesScreenState extends State<ManageStaffRolesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<String> _roles = [];
  final TextEditingController _newRoleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final roles = await _firestoreService.getStaffRoles();
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading roles: $e')),
      );
    }
  }

  Future<void> _addRole() async {
    final name = _newRoleController.text.trim();
    if (name.isEmpty) return;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final createdBy = auth.currentUser?.id;

    try {
      await _firestoreService.addStaffRole(name, createdBy: createdBy);
      _newRoleController.clear();
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding role: $e')),
        );
      }
    }
  }

  Future<void> _deleteRole(String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete "$role"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _firestoreService.deleteStaffRole(role);
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff Roles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newRoleController,
                          decoration: const InputDecoration(
                            labelText: 'New Role Name',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addRole(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addRole,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _roles.isEmpty
                      ? const Center(child: Text('No staff roles added yet.'))
                      : ListView.builder(
                          itemCount: _roles.length,
                          itemBuilder: (ctx, i) {
                            final role = _roles[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(role),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteRole(role),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
