import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/utils/calendar_exporter.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/screens/timetable_form_screen.dart';
import 'package:taskai/presentation/widgets/timetable_grid_view.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _weekStart;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _weekStart = _getStartOfWeek(DateTime.now());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  void _currentWeek() {
    setState(() {
      _weekStart = _getStartOfWeek(DateTime.now());
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  String _formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  List<TaskModel> _tasksForDate(List<TaskModel> tasks, DateTime date) {
    final target = _dateOnly(date);

    final result = tasks.where((task) {
      if (task.isLocationTask && task.startTime != null) {
        return _isSameDay(task.startTime!, target);
      }

      return _isSameDay(task.deadline, target);
    }).toList();

    result.sort((a, b) {
      final aTime = a.isLocationTask && a.startTime != null
          ? a.startTime!
          : a.deadline;
      final bTime = b.isLocationTask && b.startTime != null
          ? b.startTime!
          : b.deadline;

      return aTime.compareTo(bTime);
    });

    return result;
  }

  String _taskTimeLabel(TaskModel task) {
    if (task.isLocationTask && task.startTime != null && task.endTime != null) {
      return '${_formatTime(task.startTime!)} - ${_formatTime(task.endTime!)}';
    }

    return _formatTime(task.deadline);
  }

  String _departureLabel(TaskModel task) {
    if (!task.isLocationTask || task.startTime == null) {
      return '';
    }

    final departureTime = task.startTime!.subtract(
      Duration(minutes: task.travelMinutes),
    );

    return 'Nên đi lúc ${_formatTime(departureTime)}';
  }

  Future<void> _exportCalendar(List<TaskModel> weekTasks) async {
    if (weekTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có lịch biểu để xuất.')),
      );
      return;
    }

    try {
      await CalendarExporter.exportTasksToIcs(weekTasks);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất lịch: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);
    final timetableSlots = ref.watch(timetableProvider);

    final weekDays = List.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );

    final weekEnd = _weekStart.add(const Duration(days: 6));

    // Filter tasks occurring in the selected week
    final weekTasks = allTasks.where((task) {
      final tTime = task.isLocationTask && task.startTime != null ? task.startTime! : task.deadline;
      return tTime.isAfter(_weekStart.subtract(const Duration(seconds: 1))) &&
          tTime.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch trình & Lớp học',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_tabController.index == 0) ...[
            IconButton(
              onPressed: () => _exportCalendar(weekTasks),
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Xuất lịch tuần này (.ics)',
            ),
            IconButton(
              onPressed: _currentWeek,
              icon: const Icon(Icons.today_rounded),
              tooltip: 'Tuần hiện tại',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.checklist_rounded),
              text: 'Nhiệm vụ tuần này',
            ),
            Tab(
              icon: Icon(Icons.calendar_view_week_rounded),
              text: 'Thời khóa biểu',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Lịch nhiệm vụ và học tập theo tuần
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _previousWeek,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Lịch học và công việc',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatFullDate(_weekStart)} - ${_formatFullDate(weekEnd)}',
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _nextWeek,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: weekDays.length,
                  itemBuilder: (context, index) {
                    final date = weekDays[index];
                    final dayTasks = _tasksForDate(allTasks, date);

                    return _DayScheduleSection(
                      dateLabel: '${_weekdayLabel(date)}, ${_formatDate(date)}',
                      isToday: _isSameDay(date, DateTime.now()),
                      tasks: dayTasks,
                      taskTimeLabel: _taskTimeLabel,
                      departureLabel: _departureLabel,
                    );
                  },
                ),
              ),
            ],
          ),

          // TAB 2: Thời khóa biểu sinh viên dạng lưới
          TimetableGridView(slots: timetableSlots),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              heroTag: 'schedule_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TimetableFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm môn'),
            )
          : null,
    );
  }
}

class _DayScheduleSection extends StatelessWidget {
  final String dateLabel;
  final bool isToday;
  final List<TaskModel> tasks;
  final String Function(TaskModel task) taskTimeLabel;
  final String Function(TaskModel task) departureLabel;

  const _DayScheduleSection({
    required this.dateLabel,
    required this.isToday,
    required this.tasks,
    required this.taskTimeLabel,
    required this.departureLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Day Label
          Row(
            children: [
              if (isToday)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isToday ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withOpacity(0.15)),
              ),
              child: Text(
                'Không có lịch học hay công việc.',
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.5),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => _ScheduleTaskRow(
                task: task,
                timeLabel: taskTimeLabel(task),
                departureLabel: departureLabel(task),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTaskRow extends StatelessWidget {
  final TaskModel task;
  final String timeLabel;
  final String departureLabel;

  const _ScheduleTaskRow({
    required this.task,
    required this.timeLabel,
    required this.departureLabel,
  });

  // Timetable Pastel Styles
  Color get _backgroundColor {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFFFEBEE); // Pastel Red
      case TaskPriority.medium:
        return const Color(0xFFFFF3E0); // Pastel Orange
      case TaskPriority.low:
        return const Color(0xFFE8F5E9); // Pastel Green
    }
  }

  Color get _textColor {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFC62828);
      case TaskPriority.medium:
        return const Color(0xFFE65100);
      case TaskPriority.low:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Time indicator column
          SizedBox(
            width: 65,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                timeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          
          // Timeline Node Indicator
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _textColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 55,
                color: _textColor.withOpacity(0.25),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Right: Colored Class Block Card
          Expanded(
            child: Card(
              color: _backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _textColor.withOpacity(0.15), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag and Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: _textColor,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _textColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Destination location
                    if (task.isLocationTask &&
                        task.locationName != null &&
                        task.locationName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 13, color: _textColor.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Địa điểm: ${task.locationName}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _textColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Departure instruction
                    if (departureLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.directions_walk_rounded, size: 13, color: _textColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              departureLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Travel details
                    if (task.isLocationTask) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Thời gian di chuyển: ${task.travelMinutes} phút (${task.effectiveOrigin} → ${task.effectiveDestination})',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: _textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}