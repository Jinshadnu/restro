import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class StaffMyAttendanceScreen extends StatefulWidget {
  const StaffMyAttendanceScreen({super.key});

  @override
  State<StaffMyAttendanceScreen> createState() =>
      _StaffMyAttendanceScreenState();
}

class _StaffMyAttendanceScreenState extends State<StaffMyAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const int _attendanceStartHour = 14;
  static const int _lateAfterMinutes = 15;

  String _monthLabel(DateTime m) => DateFormat('MMMM yyyy').format(m);

  bool _isLate(DateTime ts) {
    final threshold = DateTime(ts.year, ts.month, ts.day, _attendanceStartHour)
        .add(const Duration(minutes: _lateAfterMinutes));
    return ts.isAfter(threshold);
  }

  String _dateStr(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  int _daysInMonth(DateTime m) {
    final start = DateTime(m.year, m.month, 1);
    final nextMonth = DateTime(m.year, m.month + 1, 1);
    return nextMonth.difference(start).inDays;
  }

  int _daysConsidered(DateTime month) {
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    if (!isCurrentMonth) return _daysInMonth(month);

    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(month.year, month.month, 1);
    final days = todayStart.difference(monthStart).inDays + 1;
    return days.clamp(0, _daysInMonth(month));
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final uid = (auth.currentUser?.id ?? '').toString();

    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backGroundColor,
        body: const Center(child: Text('Not authorized')),
      );
    }

    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startStr = _dateStr(monthStart);
    final endStr = _dateStr(monthEnd);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
              left: 20,
              right: 20,
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
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
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
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
                const SizedBox(height: 24),
                // Month Picker Button
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickMonth,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _monthLabel(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.streamAttendanceForUserDateRange(
                uid,
                startStr,
                endStr,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading data',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  );
                }

                final records = snap.data ?? [];

                final byDate = <String, Map<String, dynamic>>{};
                for (final a in records) {
                  final d = (a['dateStr'] ?? '').toString();
                  if (d.isEmpty) continue;
                  byDate[d] = a;
                }

                DateTime? parseTs(dynamic raw) {
                  if (raw == null) return null;
                  if (raw is DateTime) return raw;
                  final rawType = raw.runtimeType.toString();
                  if (rawType == 'Timestamp' || rawType.endsWith('Timestamp')) {
                    try {
                      return (raw as dynamic).toDate() as DateTime;
                    } catch (_) {
                      return null;
                    }
                  }
                  if (raw is String) return DateTime.tryParse(raw);
                  return null;
                }

                int approved = 0;
                int pending = 0;
                int late = 0;

                for (final e in byDate.entries) {
                  final a = e.value;
                  final status = (a['verification_status'] ?? a['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  if (status == 'approved' || status == 'verified') {
                    approved += 1;
                  } else {
                    pending += 1;
                  }

                  final ts = parseTs(a['timestamp'] ?? a['capturedAt']);
                  if (ts != null && _isLate(ts)) late += 1;
                }

                final consideredDays = _daysConsidered(_selectedMonth);
                final marked = byDate.length;
                final absent =
                    (consideredDays - marked).clamp(0, consideredDays);

                final dayRows = <_AttendanceDayRow>[];
                for (int i = 0; i < _daysInMonth(_selectedMonth); i++) {
                  final d = DateTime(
                      _selectedMonth.year, _selectedMonth.month, i + 1);
                  final ds = _dateStr(d);
                  final a = byDate[ds];

                  DateTime? captured;
                  if (a != null) {
                    captured = parseTs(a['timestamp'] ?? a['capturedAt']);
                  }

                  final status = a == null
                      ? _AttendanceDayStatus.absent
                      : _dayStatusFromRaw(
                          (a['verification_status'] ?? a['status'] ?? '')
                              .toString(),
                        );

                  dayRows.add(
                    _AttendanceDayRow(
                      date: d,
                      status: status,
                      capturedAt: captured,
                      isLate: captured != null ? _isLate(captured) : false,
                      note:
                          a == null ? null : (a['rejectionReason']?.toString()),
                    ),
                  );
                }

                final weeks = _groupIntoWeeks(dayRows);

                final screenWidth = MediaQuery.of(context).size.width;
                final textScale =
                    MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.4);
                final baseRatio = screenWidth < 360 ? 1.35 : 1.6;
                // Reduce ratio for larger text scale -> cards become taller.
                final metricsAspectRatio =
                    (baseRatio / textScale).clamp(0.95, baseRatio);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metrics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: metricsAspectRatio,
                        children: [
                          _MetricCard(
                            title: 'Approved',
                            value: approved,
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF43A047),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                          _MetricCard(
                            title: 'Late In',
                            value: late,
                            icon: Icons.access_time_rounded,
                            color: const Color(0xFFE53935),
                            bgColor: const Color(0xFFFFEBEE),
                          ),
                          _MetricCard(
                            title: 'Absents',
                            value: absent,
                            icon: Icons.cancel_outlined,
                            color: const Color(0xFF7E57C2),
                            bgColor: const Color(0xFFEDE7F6),
                          ),
                          _MetricCard(
                            title: 'Pending',
                            value: pending,
                            icon: Icons.hourglass_empty_rounded,
                            color: const Color(0xFFFFA000),
                            bgColor: const Color(0xFFFFF8E1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        'Weekly Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      for (final w in weeks) ...[
                        _WeekCard(week: w),
                        const SizedBox(height: 24),
                      ],
                    ],
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

enum _AttendanceDayStatus {
  absent,
  pending,
  approved,
  rejected,
}

_AttendanceDayStatus _dayStatusFromRaw(String raw) {
  final s = raw.toLowerCase().trim();
  if (s == 'approved' || s == 'verified') return _AttendanceDayStatus.approved;
  if (s == 'rejected') return _AttendanceDayStatus.rejected;
  return _AttendanceDayStatus.pending;
}

class _AttendanceDayRow {
  final DateTime date;
  final _AttendanceDayStatus status;
  final DateTime? capturedAt;
  final bool isLate;
  final String? note;

  _AttendanceDayRow({
    required this.date,
    required this.status,
    required this.capturedAt,
    required this.isLate,
    required this.note,
  });
}

class _AttendanceWeek {
  final DateTime start;
  final DateTime end;
  final List<_AttendanceDayRow> days;

  _AttendanceWeek({
    required this.start,
    required this.end,
    required this.days,
  });
}

List<_AttendanceWeek> _groupIntoWeeks(List<_AttendanceDayRow> days) {
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  final weeks = <_AttendanceWeek>[];

  DateTime weekStart(DateTime d) {
    final delta = d.weekday - DateTime.monday;
    final s = DateTime(d.year, d.month, d.day).subtract(Duration(days: delta));
    return s;
  }

  final byWeek = <DateTime, List<_AttendanceDayRow>>{};
  for (final d in sorted) {
    final ws = weekStart(d.date);
    (byWeek[ws] ??= []).add(d);
  }

  final keys = byWeek.keys.toList()..sort((a, b) => a.compareTo(b));
  for (final k in keys) {
    final list = byWeek[k] ?? [];
    final start = k;
    final end = k.add(const Duration(days: 6));
    weeks.add(_AttendanceWeek(start: start, end: end, days: list));
  }

  return weeks;
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final pad = (h * 0.11).clamp(8.0, 13.0);
        final iconPad = (h * 0.07).clamp(6.0, 9.0);
        final iconSize = (h * 0.17).clamp(18.0, 21.0);
        final valueSize = (h * 0.27).clamp(18.0, 25.0);
        final titleSize = (h * 0.125).clamp(10.0, 12.5);

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekCard extends StatelessWidget {
  final _AttendanceWeek week;

  const _WeekCard({required this.week});

  String _weekLabel() {
    final start = DateFormat('MMMM d').format(week.start);
    final end = DateFormat('d, yyyy').format(week.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            _weekLabel(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < week.days.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.08),
                  ),
                _DayTile(day: week.days[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  final _AttendanceDayRow day;

  const _DayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final dateNumber = DateFormat('d').format(day.date);
    final weekday = DateFormat('EEE').format(day.date);

    final capturedLabel = day.capturedAt == null
        ? 'Not marked'
        : DateFormat('hh:mm a').format(day.capturedAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Date Column
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  weekday.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusDot(),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _statusColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      capturedLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    if (day.isLate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (day.status == _AttendanceDayStatus.rejected &&
                    day.note != null &&
                    day.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      day.note!.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Color(0xFFD32F2F),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    switch (day.status) {
      case _AttendanceDayStatus.absent:
        return 'Absent';
      case _AttendanceDayStatus.pending:
        return 'Pending Review';
      case _AttendanceDayStatus.approved:
        return 'Present';
      case _AttendanceDayStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor() {
    switch (day.status) {
      case _AttendanceDayStatus.absent:
        return Colors.grey.shade400;
      case _AttendanceDayStatus.pending:
        return const Color(0xFFFFA000);
      case _AttendanceDayStatus.approved:
        return AppTheme.primaryColor;
      case _AttendanceDayStatus.rejected:
        return const Color(0xFFE53935);
    }
  }

  Widget _statusDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _statusColor(),
        shape: BoxShape.circle,
      ),
    );
  }
}
