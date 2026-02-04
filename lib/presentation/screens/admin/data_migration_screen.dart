import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  bool _isMigrating = false;
  String _status = 'Ready to migrate tasks';
  int _processedCount = 0;
  int _totalCount = 0;

  Future<void> _migrateTasks() async {
    setState(() {
      _isMigrating = true;
      _status = 'Starting migration...';
      _processedCount = 0;
    });

    try {
      final db = FirebaseFirestore.instance;
      final tasksRef = db.collection('tasks');
      final snapshot = await tasksRef.get();

      setState(() {
        _totalCount = snapshot.size;
        _status = 'Found $_totalCount tasks to migrate';
      });

      if (snapshot.docs.isEmpty) {
        setState(() {
          _status = 'No tasks found to migrate';
          _isMigrating = false;
        });
        return;
      }

      WriteBatch batch = db.batch();
      int batchCount = 0;
      const maxBatchSize = 500;

      for (final doc in snapshot.docs) {
        final taskRef = tasksRef.doc(doc.id);
        final taskData = doc.data();

        // Prepare updated data
        final updatedData = Map<String, dynamic>.from(taskData);

        // Add missing fields with defaults
        updatedData['grade'] = taskData['grade'] ?? 'normal';
        updatedData['requiresPhoto'] = taskData['requiresPhoto'] ?? false;
        updatedData['isLate'] = taskData['isLate'] ?? false;
        updatedData['reward'] = taskData['reward'] ?? 50.0;
        updatedData['ownerRejectionAt'] = taskData['ownerRejectionAt'];
        updatedData['ownerRejectionReason'] = taskData['ownerRejectionReason'];
        updatedData['rejectedBy'] = taskData['rejectedBy'];

        // Ensure consistent sopid field
        updatedData['sopid'] = taskData['sopid'] ?? taskData['sopId'] ?? '';

        batch.update(taskRef, updatedData);
        batchCount++;
        _processedCount++;

        // Update progress
        if (_processedCount % 10 == 0) {
          setState(() {
            _status = 'Migrated $_processedCount/$_totalCount tasks...';
          });
        }

        // Commit batch when it reaches limit
        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }

      // Commit remaining items
      if (batchCount > 0) {
        await batch.commit();
      }

      setState(() {
        _status = 'Migration completed! Updated $_processedCount tasks';
        _isMigrating = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _status = 'Migration failed: $e';
        _isMigrating = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migration Complete'),
        content: Text('Successfully migrated $_processedCount tasks'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migration Failed'),
        content: Text('Error: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Data Migration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will update all existing tasks to include new fields required for the scoring engine and owner override functionality.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow('Status', _status),
                    if (_totalCount > 0) ...[
                      _buildStatusRow(
                          'Progress', '$_processedCount/$_totalCount'),
                      LinearProgressIndicator(
                        value:
                            _totalCount > 0 ? _processedCount / _totalCount : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isMigrating ? null : _migrateTasks,
              icon: _isMigrating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isMigrating ? 'Migrating...' : 'Start Migration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
