import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class MonthlyAttendanceSummaryScreen extends StatefulWidget {
  const MonthlyAttendanceSummaryScreen({super.key});

  @override
  State<MonthlyAttendanceSummaryScreen> createState() =>
      _MonthlyAttendanceSummaryScreenState();
}

class _MonthlyAttendanceSummaryScreenState
    extends State<MonthlyAttendanceSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const int _attendanceStartHour = 14;
  static const int _lateAfterMinutes = 15;

  String _monthLabel(DateTime m) => DateFormat('MMMM yyyy').format(m);

  String _dateStr(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  int _daysInMonth(DateTime m) {
    final next = DateTime(m.year, m.month + 1, 1);
    final lastDay = next.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  bool _isLate(DateTime ts) {
    final threshold = DateTime(ts.year, ts.month, ts.day, _attendanceStartHour)
        .add(const Duration(minutes: _lateAfterMinutes));
    return ts.isAfter(threshold);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
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
          title: const Text('Monthly Attendance Summary'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Not authorized')),
      );
    }

    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1)
            .subtract(const Duration(days: 1));
    final startStr = _dateStr(monthStart);
    final endStr = _dateStr(monthEnd);
    final daysInMonth = _daysInMonth(_selectedMonth);

    final staffStream = isOwner
        ? _firestoreService.streamAllStaffUsers()
        : _firestoreService.streamStaffForManager(auth.currentUser?.id ?? '');

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Monthly Attendance Summary'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            label: Text(
              _monthLabel(_selectedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.streamAttendanceForDateRange(
                startStr,
                endStr,
              ),
              builder: (context, attendanceSnap) {
                if (attendanceSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (attendanceSnap.hasError) {
                  return Center(child: Text('Error: ${attendanceSnap.error}'));
                }

                final attendances = attendanceSnap.data ?? [];

                final attendanceByUser = <String, List<Map<String, dynamic>>>{};
                for (final a in attendances) {
                  final uid = (a['userId'] ?? a['staff_id'] ?? '').toString();
                  if (uid.isEmpty) continue;
                  (attendanceByUser[uid] ??= []).add(a);
                }

                staff.sort((a, b) {
                  final an = (a['name'] ?? '').toString().toLowerCase();
                  final bn = (b['name'] ?? '').toString().toLowerCase();
                  return an.compareTo(bn);
                });

                if (staff.isEmpty) {
                  return const Center(child: Text('No staff found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = staff[index];
                    final uid = (s['id'] ?? '').toString();
                    final name = (s['name'] ?? 'Unknown').toString();
                    final roleDisplay =
                        (s['staff_role'] ?? s['staffRole'] ?? '')
                            .toString()
                            .trim();

                    final userAttendance = attendanceByUser[uid] ?? const [];

                    final uniqueDays = <String>{};
                    int present = 0;
                    int pending = 0;
                    int rejected = 0;
                    int late = 0;

                    for (final a in userAttendance) {
                      final dateStr = (a['dateStr'] ?? '').toString();
                      if (dateStr.isEmpty) continue;
                      uniqueDays.add(dateStr);

                      final status = (a['verification_status'] ?? a['status'] ??
                              '')
                          .toString()
                          .toLowerCase();

                      if (status == 'approved' || status == 'verified') {
                        present += 1;
                      } else if (status == 'rejected') {
                        rejected += 1;
                      } else {
                        pending += 1;
                      }

                      final ts = a['timestamp'] ?? a['capturedAt'];
                      final dt = _firestoreService.parseDateTimePublic(ts);
                      if (dt != null && _isLate(dt)) {
                        late += 1;
                      }
                    }

                    final absent = daysInMonth - uniqueDays.length;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (roleDisplay.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          roleDisplay,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${uniqueDays.length}/$daysInMonth',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip('Present', present, Colors.green),
                              _chip('Pending', pending, Colors.orange),
                              _chip('Rejected', rejected, Colors.red),
                              _chip('Late', late, Colors.purple),
                              _chip('Absent', absent, Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
