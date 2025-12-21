import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/sop_provider.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/utils/theme/theme.dart';

class ManageSopScreen extends StatefulWidget {
  const ManageSopScreen({super.key});

  @override
  State<ManageSopScreen> createState() => _ManageSopScreenState();
}

class _ManageSopScreenState extends State<ManageSopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SopProvider>(context, listen: false).loadSOPs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manage SOP", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          Navigator.pushNamed(context, "/addSop");
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<SopProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sops.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No SOPs found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadSOPs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.sops.length,
              itemBuilder: (context, index) {
                final sop = provider.sops[index];

                return _sopCard(
                  title: sop.title,
                  description: sop.description,
                  onEdit: () {
                    // Navigate to edit SOP
                  },
                  onDelete: () {
                    _confirmDelete(context, sop.id, provider);
                  },
                  onTap: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  //            SOP Card UI Widget
  // ===========================================================
  Widget _sopCard({
    required String title,
    required String description,
    required VoidCallback onTap,
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
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ),
        trailing: PopupMenuButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 10),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // ===========================================================
  //       Delete Confirmation Dialog
  // ===========================================================
  void _confirmDelete(
      BuildContext context, String sopId, SopProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete SOP"),
        content: const Text(
          "Are you sure you want to delete this SOP?",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await provider.deleteSop(sopId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SOP deleted successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
