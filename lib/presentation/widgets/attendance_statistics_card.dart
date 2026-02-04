import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class AttendanceStatisticsCard extends StatefulWidget {
  final bool isOwner;

  const AttendanceStatisticsCard({
    super.key,
    required this.isOwner,
  });

  @override
  State<AttendanceStatisticsCard> createState() =>
      _AttendanceStatisticsCardState();
}

class _AttendanceStatisticsCardState extends State<AttendanceStatisticsCard> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedDate = DateTime.now();

  static const int _attendanceStartHour = 14;
  static const int _lateAfterMinutes = 15;

  String _dateStr(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  bool _isLate(DateTime ts) {
    final threshold = DateTime(ts.year, ts.month, ts.day, _attendanceStartHour)
        .add(const Duration(minutes: _lateAfterMinutes));
    return ts.isAfter(threshold);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final managerId = auth.currentUser?.id ?? '';

    final staffStream = widget.isOwner
        ? _firestoreService.streamAllStaffUsers()
        : _firestoreService.streamStaffForManager(managerId);

    final dateStr = _dateStr(_selectedDate);

    final isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: staffStream,
      builder: (context, staffSnap) {
        final staff = staffSnap.data ?? [];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.streamAttendanceForDate(dateStr),
          builder: (context, attendanceSnap) {
            final attendances = attendanceSnap.data ?? [];

            final attendanceByUser = <String, Map<String, dynamic>>{};
            for (final a in attendances) {
              final uid = (a['userId'] ?? a['staff_id'] ?? '').toString();
              if (uid.isEmpty) continue;
              attendanceByUser[uid] = a;
            }

            int total = 0;
            int present = 0;
            int late = 0;
            int submitted = 0;

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

            for (final s in staff) {
              final uid = (s['id'] ?? '').toString();
              if (uid.isEmpty) continue;
              total++;

              final attendance = attendanceByUser[uid];
              if (attendance == null) continue;

              submitted++;

              final ts =
                  parseTs(attendance['timestamp'] ?? attendance['capturedAt']);
              if (ts != null && _isLate(ts)) {
                late++;
              } else {
                present++;
              }
            }

            final notMarked = (total - submitted).clamp(0, total);
            final absent = notMarked;

            final subtitle =
                'Based on ${DateFormat('MMM d, yyyy').format(_selectedDate)}';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
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
                            const Text(
                              'Attendance Statistics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('dd MMM')
                                        .format(_selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.0,
                    children: [
                      _StatTile(
                        count: notMarked,
                        label: 'Not marked',
                        color: const Color(0xFF9E9E9E),
                      ),
                      _StatTile(
                        count: present,
                        label: 'Present',
                        color: const Color(0xFF4CAF50),
                      ),
                      _StatTile(
                        count: absent,
                        label: 'Absence',
                        color: const Color(0xFFF44336),
                      ),
                      _StatTile(
                        count: late,
                        label: 'Late',
                        color: const Color(0xFFFFC107),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    count: total,
                    label: 'Heads',
                    color: AppTheme.primaryColor,
                    wide: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool wide;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count staff',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
