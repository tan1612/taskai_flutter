import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/timetable_slot.dart';
import 'package:taskai/presentation/screens/timetable_form_screen.dart';

class TimetableGridView extends ConsumerWidget {
  final List<TimetableSlot> slots;

  const TimetableGridView({super.key, required this.slots});

  static const double _rowHeight = 70.0;
  static const double _headerHeight = 50.0;
  static const double _labelWidth = 80.0;
  static const double _columnWidth = 120.0;

  String _getDayLabel(int day) {
    if (day == 7) return 'Chủ Nhật';
    return 'Thứ ${day + 1}';
  }

  Color _getPastelColor(String subjectName, bool isDark) {
    final hash = subjectName.hashCode;
    final index = hash.abs() % 6;
    if (isDark) {
      final darkPastels = [
        const Color(0xFF2C353F), // Steel Blue
        const Color(0xFF1E3A27), // Forest Dark
        const Color(0xFF4A232E), // Plum Dark
        const Color(0xFF3D352F), // Warm Brown
        const Color(0xFF1F2E3E), // Ocean Dark
        const Color(0xFF33203E), // Purple Dark
      ];
      return darkPastels[index];
    } else {
      final lightPastels = [
        const Color(0xFFFFEBEE), // Soft Red
        const Color(0xFFE8F5E9), // Soft Green
        const Color(0xFFE3F2FD), // Soft Blue
        const Color(0xFFFFFDE7), // Soft Yellow
        const Color(0xFFF3E5F5), // Soft Purple
        const Color(0xFFE0F7FA), // Soft Cyan
      ];
      return lightPastels[index];
    }
  }

  Color _getTextColor(String subjectName, bool isDark) {
    final hash = subjectName.hashCode;
    final index = hash.abs() % 6;
    if (isDark) {
      return Colors.white.withOpacity(0.9);
    } else {
      final darkTexts = [
        const Color(0xFFC62828), // Dark Red
        const Color(0xFF2E7D32), // Dark Green
        const Color(0xFF1565C0), // Dark Blue
        const Color(0xFFE65100), // Dark Orange
        const Color(0xFF6A1B9A), // Dark Purple
        const Color(0xFF00838F), // Dark Cyan
      ];
      return darkTexts[index];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final double totalWidth = _labelWidth + (_columnWidth * 7);
    final double totalHeight = _headerHeight + (_rowHeight * 15);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: totalWidth,
          height: totalHeight,
          decoration: BoxDecoration(
            color: scheme.surface,
          ),
          child: Stack(
            children: [
              // 1. Vẽ dòng tiêu đề cột (Thứ 2 - CN)
              Positioned(
                left: 0,
                top: 0,
                width: totalWidth,
                height: _headerHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.4),
                    border: Border(
                      bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Góc trống trên cùng bên trái
                      Container(
                        width: _labelWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(
                          'Tiết',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      // 7 Cột Thứ 2 -> CN
                      ...List.generate(7, (index) {
                        final day = index + 1;
                        return Container(
                          width: _columnWidth,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                            ),
                          ),
                          child: Text(
                            _getDayLabel(day),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // 2. Vẽ lưới ô học sinh và dòng kẻ ngang dọc
              ...List.generate(15, (rowIndex) {
                final period = rowIndex + 1;
                return Positioned(
                  left: 0,
                  top: _headerHeight + (rowIndex * _rowHeight),
                  width: totalWidth,
                  height: _rowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Cột hiển thị Tiết học
                        Container(
                          width: _labelWidth,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(0.2),
                            border: Border(
                              right: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tiết $period',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                TimetableSlot.periodStartTimes[period] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 7 ô tương ứng 7 ngày học trong tiết này
                        ...List.generate(7, (colIndex) {
                          return Container(
                            width: _columnWidth,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: scheme.outlineVariant.withOpacity(0.15)),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              // 3. Đè các thẻ môn học lên lưới (Timeline Blocks)
              ...slots.map((slot) {
                final int colIndex = slot.dayOfWeek - 1;
                final int rowIndex = slot.startPeriod - 1;
                final int span = slot.endPeriod - slot.startPeriod + 1;

                final double cardLeft = _labelWidth + (colIndex * _columnWidth) + 3;
                final double cardTop = _headerHeight + (rowIndex * _rowHeight) + 3;
                final double cardWidth = _columnWidth - 6;
                final double cardHeight = (span * _rowHeight) - 6;

                final bgColor = _getPastelColor(slot.subjectName, isDark);
                final textColor = _getTextColor(slot.subjectName, isDark);

                return Positioned(
                  left: cardLeft,
                  top: cardTop,
                  width: cardWidth,
                  height: cardHeight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TimetableFormScreen(slot: slot),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: textColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên môn học
                          Text(
                            slot.subjectName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          // Phòng học
                          if (slot.room.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.meeting_room_rounded, size: 10, color: textColor.withOpacity(0.8)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    slot.room,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.9),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          // Giờ học
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 10, color: textColor.withOpacity(0.8)),
                              const SizedBox(width: 3),
                              Text(
                                '${slot.startTimeLabel} - ${slot.endTimeLabel}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Ngày học (Ngày bắt đầu - Ngày kết thúc)
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 10, color: textColor.withOpacity(0.8)),
                              const SizedBox(width: 3),
                              Text(
                                '${slot.startDate.day.toString().padLeft(2, '0')}/${slot.startDate.month.toString().padLeft(2, '0')} - ${slot.endDate.day.toString().padLeft(2, '0')}/${slot.endDate.month.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
