import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/task_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getStartOfWeek(DateTime.now());
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

    return 'Deadline ${_formatTime(task.deadline)}';
  }

  String _departureLabel(TaskModel task) {
    if (!task.isLocationTask || task.startTime == null) {
      return '';
    }

    final departureTime = task.startTime!.subtract(
      Duration(minutes: task.travelMinutes),
    );

    return 'Nên xuất phát lúc ${_formatTime(departureTime)}';
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5252);
      case TaskPriority.medium:
        return const Color(0xFFFFB020);
      case TaskPriority.low:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final weekDays = List.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );

    final weekEnd = _weekStart.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch biểu',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _currentWeek,
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Tuần hiện tại',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Card(
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
                            'Thời khóa biểu tuần',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatFullDate(_weekStart)} - ${_formatFullDate(weekEnd)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
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
                final dayTasks = _tasksForDate(tasks, date);

                return _DayScheduleSection(
                  dateLabel: '${_weekdayLabel(date)}, ${_formatDate(date)}',
                  isToday: _isSameDay(date, DateTime.now()),
                  tasks: dayTasks,
                  taskTimeLabel: _taskTimeLabel,
                  departureLabel: _departureLabel,
                  priorityColor: _priorityColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayScheduleSection extends StatelessWidget {
  final String dateLabel;
  final bool isToday;
  final List<TaskModel> tasks;
  final String Function(TaskModel task) taskTimeLabel;
  final String Function(TaskModel task) departureLabel;
  final Color Function(TaskPriority priority) priorityColor;

  const _DayScheduleSection({
    required this.dateLabel,
    required this.isToday,
    required this.tasks,
    required this.taskTimeLabel,
    required this.departureLabel,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: isToday ? scheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Không có lịch trong ngày này.',
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => _ScheduleTaskTile(
                task: task,
                timeLabel: taskTimeLabel(task),
                departureLabel: departureLabel(task),
                priorityColor: priorityColor(task.priority),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTaskTile extends StatelessWidget {
  final TaskModel task;
  final String timeLabel;
  final String departureLabel;
  final Color priorityColor;

  const _ScheduleTaskTile({
    required this.task,
    required this.timeLabel,
    required this.departureLabel,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 74,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                task.isLocationTask
                    ? Icons.route_rounded
                    : Icons.task_alt_rounded,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.isLocationTask &&
                      task.locationName != null &&
                      task.locationName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 15,
                          color: scheme.onSurface.withOpacity(0.65),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.locationName!.trim(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (departureLabel.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          size: 15,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            departureLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}