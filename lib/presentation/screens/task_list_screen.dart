import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/task_provider.dart';
import 'package:taskai/presentation/screens/task_form_screen.dart';
import 'package:taskai/presentation/widgets/task_card.dart';

enum TaskStatusFilter { all, active, done }

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  DateTime _selectedDay = DateTime.now();
  String _selectedTag = 'Tất cả';
  TaskStatusFilter _status = TaskStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);

    final tags = ['Tất cả', ...{for (final task in allTasks) task.tag}];

    final filtered = allTasks.where((task) {
      final sameDay = task.deadline.year == _selectedDay.year &&
          task.deadline.month == _selectedDay.month &&
          task.deadline.day == _selectedDay.day;

      final matchTag = _selectedTag == 'Tất cả' || task.tag == _selectedTag;

      final matchStatus = switch (_status) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.active => !task.isDone,
        TaskStatusFilter.done => task.isDone,
      };

      return sameDay && matchTag && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách Task',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar<TaskModel>(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2035),
                focusedDay: _selectedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                locale: 'vi_VN',
                calendarFormat: CalendarFormat.week,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Tháng',
                  CalendarFormat.twoWeeks: '2 tuần',
                  CalendarFormat.week: 'Tuần',
                },
                eventLoader: (day) {
                  return allTasks.where((task) {
                    return task.deadline.year == day.year &&
                        task.deadline.month == day.month &&
                        task.deadline.day == day.day;
                  }).toList();
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() => _selectedDay = selectedDay);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DropdownButton<String>(
                value: tags.contains(_selectedTag) ? _selectedTag : 'Tất cả',
                items: tags
                    .map(
                      (tag) => DropdownMenuItem(
                        value: tag,
                        child: Text(tag),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTag = value ?? 'Tất cả'),
              ),
              SegmentedButton<TaskStatusFilter>(
                segments: const [
                  ButtonSegment(
                    value: TaskStatusFilter.all,
                    label: Text('Tất cả'),
                  ),
                  ButtonSegment(
                    value: TaskStatusFilter.active,
                    label: Text('Chưa xong'),
                  ),
                  ButtonSegment(
                    value: TaskStatusFilter.done,
                    label: Text('Đã xong'),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (value) =>
                    setState(() => _status = value.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const _EmptyTaskList()
          else
            ...filtered.map(
              (task) => TaskCard(
                task: task,
                onToggle: () => ref.read(taskProvider.notifier).toggleDone(task),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskFormScreen(task: task),
                  ),
                ),
                onDelete: () => ref.read(taskProvider.notifier).delete(task.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTaskList extends StatelessWidget {
  const _EmptyTaskList();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text('Không có task phù hợp với bộ lọc hiện tại.'),
        ),
      ),
    );
  }
}
