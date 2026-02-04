import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';

enum _AttendanceFilterStatus { all, present, absent, late }

class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  State<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = 'All';
  _AttendanceFilterStatus _selectedStatus = _AttendanceFilterStatus.all;

  static const int _attendanceStartHour = 14;
  static const int _lateAfterMinutes = 15;

  String _dateStr(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  bool _isLate(DateTime ts) {
    final threshold = DateTime(ts.year, ts.month, ts.day, _attendanceStartHour)
        .add(const Duration(minutes: _lateAfterMinutes));
    return ts.isAfter(threshold);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final role = (auth.currentUser?.role ?? '').toString().toLowerCase();
    final isOwner = role == 'owner';
    final isManager = role == 'manager';

    if (!isOwner && !isManager) {
      return Scaffold(
        backgroundColor: AppTheme.backGroundColor,
        appBar: AppBar(
          title: const Text('Attendance Overview'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Not authorized'),
        ),
      );
    }

    final dateStr = _dateStr(_selectedDate);

    final staffStream = isOwner
        ? _firestoreService.streamAllStaffUsers()
        : _firestoreService.streamStaffForManager(auth.currentUser?.id ?? '');

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Attendance Overview'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Select date',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: staffStream,
          builder: (context, staffSnap) {
            if (staffSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (staffSnap.hasError) {
              return Center(child: Text('Error: ${staffSnap.error}'));
            }

            final staff = staffSnap.data ?? [];

            final departments = <String>{'All'};
            for (final s in staff) {
              final dep =
                  (s['staff_role'] ?? s['staffRole'] ?? '').toString().trim();
              if (dep.isNotEmpty) departments.add(dep);
            }
            final departmentItems = departments.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

            if (!departmentItems.contains(_selectedDepartment)) {
              _selectedDepartment = 'All';
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.streamAttendanceForDate(dateStr),
              builder: (context, attendanceSnap) {
                if (attendanceSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (attendanceSnap.hasError) {
                  return Center(child: Text('Error: ${attendanceSnap.error}'));
                }

                final attendances = attendanceSnap.data ?? [];
                final attendanceByUser = <String, Map<String, dynamic>>{};
                for (final a in attendances) {
                  final uid = (a['userId'] ?? a['staff_id'] ?? '').toString();
                  if (uid.isEmpty) continue;
                  attendanceByUser[uid] = a;
                }

                final rows = <Map<String, dynamic>>[];
                for (final s in staff) {
                  final uid = (s['id'] ?? '').toString();
                  if (uid.isEmpty) continue;

                  final staffName = (s['name'] ?? 'Unknown').toString();
                  final staffRole =
                      (s['staff_role'] ?? s['staffRole'] ?? '').toString();

                  if (_selectedDepartment != 'All' &&
                      staffRole.trim() != _selectedDepartment) {
                    continue;
                  }

                  final attendance = attendanceByUser[uid];
                  final submitted = attendance != null;

                  DateTime? submittedAt;
                  if (submitted) {
                    final raw =
                        attendance['timestamp'] ?? attendance['capturedAt'];
                    if (raw is DateTime) {
                      submittedAt = raw;
                    } else {
                      final rawType = raw?.runtimeType.toString();
                      if (rawType == 'Timestamp' ||
                          (rawType?.endsWith('Timestamp') ?? false)) {
                        try {
                          submittedAt = (raw as dynamic).toDate() as DateTime;
                        } catch (_) {
                          submittedAt = null;
                        }
                      } else if (raw is String) {
                        submittedAt = DateTime.tryParse(raw);
                      }
                    }
                  }

                  final isLate = submittedAt != null && _isLate(submittedAt);

                  String statusLabel;
                  if (!submitted) {
                    statusLabel = 'Absent';
                  } else if (isLate) {
                    statusLabel = 'Late';
                  } else {
                    statusLabel = 'Present';
                  }

                  if (_selectedStatus == _AttendanceFilterStatus.present &&
                      statusLabel != 'Present') {
                    continue;
                  }
                  if (_selectedStatus == _AttendanceFilterStatus.absent &&
                      statusLabel != 'Absent') {
                    continue;
                  }
                  if (_selectedStatus == _AttendanceFilterStatus.late &&
                      statusLabel != 'Late') {
                    continue;
                  }

                  rows.add({
                    'staffName': staffName,
                    'staffId': uid,
                    'staffRole': staffRole,
                    'statusLabel': statusLabel,
                    'submittedAt': submittedAt,
                  });
                }

                final presentCount =
                    rows.where((e) => e['statusLabel'] == 'Present').length;
                final lateCount =
                    rows.where((e) => e['statusLabel'] == 'Late').length;
                final absentCount =
                    rows.where((e) => e['statusLabel'] == 'Absent').length;

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('EEE, MMM d, yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$presentCount P  •  $lateCount L  •  $absentCount A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: departmentItems
                                      .map(
                                        (d) => DropdownMenuItem<String>(
                                          value: d,
                                          child: Text(
                                            d,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedDepartment = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<
                                    _AttendanceFilterStatus>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: _AttendanceFilterStatus.all,
                                      child: Text('All'),
                                    ),
                                    DropdownMenuItem(
                                      value: _AttendanceFilterStatus.present,
                                      child: Text('Present'),
                                    ),
                                    DropdownMenuItem(
                                      value: _AttendanceFilterStatus.late,
                                      child: Text('Late'),
                                    ),
                                    DropdownMenuItem(
                                      value: _AttendanceFilterStatus.absent,
                                      child: Text('Absent'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedStatus = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(
                              child: Text('No staff found for filters.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = rows[index];
                                final statusLabel =
                                    (item['statusLabel'] ?? '').toString();

                                Color chipColor;
                                if (statusLabel == 'Present') {
                                  chipColor = const Color(0xFF4CAF50);
                                } else if (statusLabel == 'Late') {
                                  chipColor = const Color(0xFFFFC107);
                                } else {
                                  chipColor = const Color(0xFFF44336);
                                }

                                final submittedAt =
                                    item['submittedAt'] as DateTime?;
                                final submittedText = submittedAt == null
                                    ? '—'
                                    : DateFormat('h:mm a').format(submittedAt);

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.black.withOpacity(0.05)),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 10,
                                          offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.12),
                                        child: const Icon(Icons.person,
                                            color: AppTheme.primaryColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (item['staffName'] ?? 'Unknown')
                                                  .toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${(item['staffRole'] ?? '').toString()}  •  ${(item['staffId'] ?? '').toString()}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  chipColor.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                  color: chipColor
                                                      .withOpacity(0.28)),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                color: chipColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            submittedText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
