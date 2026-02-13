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
        appBar: AppBar(
          title: const Text('My Attendance'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Not authorized')),
      );
    }

    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startStr = _dateStr(monthStart);
    final endStr = _dateStr(monthEnd);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Attendance',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.streamAttendanceForUserDateRange(
            uid,
            startStr,
            endStr,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
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
            final absent = (consideredDays - marked).clamp(0, consideredDays);

            final dayRows = <_AttendanceDayRow>[];
            for (int i = 0; i < _daysInMonth(_selectedMonth); i++) {
              final d =
                  DateTime(_selectedMonth.year, _selectedMonth.month, i + 1);
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
                  note: a == null ? null : (a['rejectionReason']?.toString()),
                ),
              );
            }

            final weeks = _groupIntoWeeks(dayRows);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MonthPickerField(
                    label: _monthLabel(_selectedMonth),
                    onTap: _pickMonth,
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.25,
                    children: [
                      _MetricCard(
                        title: 'Late In',
                        value: late,
                        color: const Color(0xFFE53935),
                      ),
                      _MetricCard(
                        title: 'Absents',
                        value: absent,
                        color: const Color(0xFF7E57C2),
                      ),
                      _MetricCard(
                        title: 'Pending',
                        value: pending,
                        color: const Color(0xFFFFA000),
                      ),
                      _MetricCard(
                        title: 'Approved',
                        value: approved,
                        color: const Color(0xFF43A047),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final w in weeks) ...[
                    _WeekCard(week: w),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            );
          },
        ),
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

class _MonthPickerField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MonthPickerField({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final _AttendanceWeek week;

  const _WeekCard({required this.week});

  String _weekLabel() {
    final start = DateFormat('dd MMM').format(week.start);
    final end = DateFormat('dd MMM').format(week.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int absent = 0;
    int late = 0;

    for (final d in week.days) {
      if (d.status == _AttendanceDayStatus.approved) approved += 1;
      if (d.status == _AttendanceDayStatus.pending) pending += 1;
      if (d.status == _AttendanceDayStatus.rejected) rejected += 1;
      if (d.status == _AttendanceDayStatus.absent) absent += 1;
      if (d.isLate) late += 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Week',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weekLabel(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  if (absent > 0) _miniPill('Absent', absent, Colors.red),
                  if (pending > 0) _miniPill('Pending', pending, Colors.orange),
                  if (approved > 0) _miniPill('Ok', approved, Colors.green),
                  if (rejected > 0) _miniPill('Rej', rejected, Colors.purple),
                  if (late > 0) _miniPill('Late', late, Colors.brown),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: week.days.map((d) => _DayTile(day: d)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final _AttendanceDayRow day;

  const _DayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final dateNumber = DateFormat('dd').format(day.date);
    final weekday = DateFormat('EEE').format(day.date);

    final capturedLabel = day.capturedAt == null
        ? '-'
        : DateFormat('hh:mm a').format(day.capturedAt!.toLocal());

    final statusChip = _statusChip();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Text(
                  dateNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekday,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selfie: $capturedLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    statusChip,
                  ],
                ),
                if (day.isLate)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Marked late',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.brown.withOpacity(0.9),
                      ),
                    ),
                  ),
                if (day.status == _AttendanceDayStatus.rejected &&
                    day.note != null &&
                    day.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      day.note!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.55),
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

  Widget _statusChip() {
    switch (day.status) {
      case _AttendanceDayStatus.absent:
        return _chip('Absent', const Color(0xFFE53935));
      case _AttendanceDayStatus.pending:
        return _chip('Pending', const Color(0xFFFFA000));
      case _AttendanceDayStatus.approved:
        return _chip('Approved', const Color(0xFF43A047));
      case _AttendanceDayStatus.rejected:
        return _chip('Rejected', const Color(0xFF7E57C2));
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
