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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Custom Gradient Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    const Text(
                      'Monthly Attendance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
                const SizedBox(height: 24),
                // Month Selector
                InkWell(
                  onTap: _pickMonth,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _monthLabel(_selectedMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
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
                  return Center(
                      child: Text('Error: ${staffSnap.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                final staff = staffSnap.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.streamAttendanceForDateRange(
                    startStr,
                    endStr,
                  ),
                  builder: (context, attendanceSnap) {
                    if (attendanceSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (attendanceSnap.hasError) {
                      return Center(
                          child: Text('Error: ${attendanceSnap.error}',
                              style: const TextStyle(color: Colors.red)));
                    }

                    final attendances = attendanceSnap.data ?? [];

                    final attendanceByUser =
                        <String, List<Map<String, dynamic>>>{};
                    for (final a in attendances) {
                      final uid =
                          (a['userId'] ?? a['staff_id'] ?? '').toString();
                      if (uid.isEmpty) continue;
                      (attendanceByUser[uid] ??= []).add(a);
                    }

                    staff.sort((a, b) {
                      final an = (a['name'] ?? '').toString().toLowerCase();
                      final bn = (b['name'] ?? '').toString().toLowerCase();
                      return an.compareTo(bn);
                    });

                    if (staff.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No staff found',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      itemCount: staff.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final s = staff[index];
                        final uid = (s['id'] ?? '').toString();
                        final name = (s['name'] ?? 'Unknown').toString();
                        final roleDisplay =
                            (s['staff_role'] ?? s['staffRole'] ?? '')
                                .toString()
                                .trim();

                        final userAttendance =
                            attendanceByUser[uid] ?? const [];

                        final uniqueDays = <String>{};
                        int present = 0;
                        int pending = 0;
                        int rejected = 0;
                        int late = 0;

                        for (final a in userAttendance) {
                          final dateStr = (a['dateStr'] ?? '').toString();
                          if (dateStr.isEmpty) continue;
                          uniqueDays.add(dateStr);

                          final status =
                              (a['verification_status'] ?? a['status'] ?? '')
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
                          final dt =
                              _firestoreService.parseDateTimePublic(ts);
                          if (dt != null && _isLate(dt)) {
                            late += 1;
                          }
                        }

                        final absent = daysInMonth - uniqueDays.length;
                        final attendancePercentage =
                            (uniqueDays.length / daysInMonth).clamp(0.0, 1.0);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // Potentially navigate to detailed view
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Initials Avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
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
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (roleDisplay.isNotEmpty)
                                                Text(
                                                  roleDisplay,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: (attendancePercentage >= 0.8)
                                                ? Colors.green.withOpacity(0.1)
                                                : (attendancePercentage >= 0.5)
                                                    ? Colors.orange
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${(attendancePercentage * 100).toInt()}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: (attendancePercentage >=
                                                      0.8)
                                                  ? Colors.green
                                                  : (attendancePercentage >=
                                                          0.5)
                                                      ? Colors.orange
                                                      : Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Stats Rows
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStatItem('Present', present,
                                            Colors.green, Icons.check_circle),
                                        _buildVerticalDivider(),
                                        _buildStatItem('Pending', pending,
                                            Colors.blue, Icons.hourglass_top),
                                        _buildVerticalDivider(),
                                        _buildStatItem('Rejected', rejected,
                                            Colors.redAccent, Icons.cancel),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 1,
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatItem('Late', late,
                                            Colors.orange, Icons.access_time),
                                        _buildVerticalDivider(),
                                        _buildStatItem('Absent', absent,
                                            Colors.grey, Icons.not_interested),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStatItem(
      String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
