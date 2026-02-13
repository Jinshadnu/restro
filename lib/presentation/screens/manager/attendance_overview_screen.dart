import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Custom Gradient Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 20,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, AppRoutes.monthlyAttendanceSummary);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_view_month_rounded,
                            color: Colors.white, size: 20),
                      ),
                      tooltip: 'Monthly summary',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _pickDate,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_rounded,
                            color: Colors.white, size: 20),
                      ),
                      tooltip: 'Select date',
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
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
                  final dep = (s['staff_role'] ?? s['staffRole'] ?? '')
                      .toString()
                      .trim();
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
                    if (attendanceSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (attendanceSnap.hasError) {
                      return Center(
                          child: Text('Error: ${attendanceSnap.error}'));
                    }

                    final attendances = attendanceSnap.data ?? [];
                    final attendanceByUser = <String, Map<String, dynamic>>{};
                    for (final a in attendances) {
                      final uid =
                          (a['userId'] ?? a['staff_id'] ?? '').toString();
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
                              submittedAt =
                                  (raw as dynamic).toDate() as DateTime;
                            } catch (_) {
                              submittedAt = null;
                            }
                          } else if (raw is String) {
                            submittedAt = DateTime.tryParse(raw);
                          }
                        }
                      }

                      final isLate =
                          submittedAt != null && _isLate(submittedAt);

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
                        // Summary Card
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMMM d, yyyy')
                                            .format(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE').format(_selectedDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Stats Summary
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildMiniStat(
                                            presentCount, Colors.green, "P"),
                                        const SizedBox(width: 12),
                                        _buildMiniStat(
                                            lateCount, Colors.orange, "L"),
                                        const SizedBox(width: 12),
                                        _buildMiniStat(
                                            absentCount, Colors.red, "A"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      value: _selectedDepartment,
                                      label: "Department",
                                      items: departmentItems,
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(
                                              () => _selectedDepartment = v);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<
                                        _AttendanceFilterStatus>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Status',
                                        labelStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 0),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: _AttendanceFilterStatus.all,
                                          child: Text('All Status'),
                                        ),
                                        DropdownMenuItem(
                                          value:
                                              _AttendanceFilterStatus.present,
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
                                        if (v != null)
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
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search_off_rounded,
                                          size: 48, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No staff found for filters.',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 20),
                                  itemCount: rows.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = rows[index];
                                    final statusLabel =
                                        (item['statusLabel'] ?? '').toString();

                                    Color statusColor;
                                    IconData statusIcon;
                                    if (statusLabel == 'Present') {
                                      statusColor = Colors.green;
                                      statusIcon = Icons.check_circle_rounded;
                                    } else if (statusLabel == 'Late') {
                                      statusColor = Colors.orange;
                                      statusIcon = Icons.access_time_rounded;
                                    } else {
                                      statusColor = Colors.red;
                                      statusIcon = Icons.cancel_rounded;
                                    }

                                    final submittedAt =
                                        item['submittedAt'] as DateTime?;
                                    final submittedText = submittedAt == null
                                        ? '—'
                                        : DateFormat('h:mm a')
                                            .format(submittedAt);

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: AppTheme
                                                .primaryColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              (item['staffName'] ?? 'U')
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (item['staffName'] ??
                                                          'Unknown')
                                                      .toString(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  (item['staffRole'] ?? '')
                                                      .toString(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[600],
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: statusColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(statusIcon,
                                                        size: 14,
                                                        color: statusColor),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      statusLabel,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                submittedText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[400],
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
        ],
      ),
    );
  }

  Widget _buildMiniStat(int count, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$count",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: Colors.grey[500],
            fontFeatures: const [FontFeature.superscripts()],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      items: items
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
      onChanged: onChanged,
    );
  }
}
