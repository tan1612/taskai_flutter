import 'package:flutter/material.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/screens/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppTheme.danger;
      case TaskPriority.medium:
        return AppTheme.warning;
      case TaskPriority.low:
        return AppTheme.success;
    }
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute - $day/$month/$year';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String get _timeLabel {
    if (task.isLocationTask && task.startTime != null && task.endTime != null) {
      return '${_formatTime(task.startTime!)} - ${_formatTime(task.endTime!)}';
    }

    return _formatDateTime(task.deadline);
  }

  String get _reminderLabel {
    switch (task.reminderMinutes) {
      case 0:
        return 'Không nhắc';
      case -1:
        return 'Demo 10 giây';
      case 5:
        return 'Nhắc trước 5 phút';
      case 10:
        return 'Nhắc trước 10 phút';
      case 15:
        return 'Nhắc trước 15 phút';
      case 30:
        return 'Nhắc trước 30 phút';
      case 60:
        return 'Nhắc trước 1 tiếng';
      case 1440:
        return 'Nhắc trước 1 ngày';
      default:
        return 'Nhắc trước ${task.reminderMinutes} phút';
    }
  }

  Color get _reminderColor {
    if (task.reminderMinutes == 0) {
      return Colors.grey;
    }

    if (task.reminderMinutes == -1) {
      return AppTheme.secondary;
    }

    return AppTheme.primary;
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 15,
      decoration: task.isDone ? TextDecoration.lineThrough : null,
      color: task.isDone ? scheme.onSurface.withOpacity(0.45) : null,
    );

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Xóa công việc?'),
                  content: Text('Bạn có chắc muốn xóa "${task.title}" không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),

          // Quan trọng: bấm vào card sẽ mở chi tiết
          onTap: () => _openDetail(context),

          leading: Checkbox(
            value: task.isDone,
            onChanged: (_) => onToggle(),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(task: task),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: task.isLocationTask
                      ? Icons.access_time_rounded
                      : Icons.schedule_rounded,
                  label: _timeLabel,
                  color: scheme.primary,
                ),
                if (task.isLocationTask &&
                    task.locationName != null &&
                    task.locationName!.trim().isNotEmpty)
                  _InfoChip(
                    icon: Icons.place_rounded,
                    label: task.locationName!.trim(),
                    color: AppTheme.secondary,
                  ),
                _InfoChip(
                  icon: Icons.flag_rounded,
                  label: task.priority.label,
                  color: _priorityColor,
                ),
                _InfoChip(
                  icon: Icons.sell_rounded,
                  label: task.tag,
                  color: scheme.secondary,
                ),
                _InfoChip(
                  icon: Icons.notifications_active_rounded,
                  label: _reminderLabel,
                  color: _reminderColor,
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'detail') {
                _openDetail(context);
              }

              if (value == 'edit') {
                onEdit();
              }

              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'detail',
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded),
                      SizedBox(width: 8),
                      Text('Chi tiết'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final TaskModel task;

  const _TypeBadge({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final isLocation = task.isLocationTask;
    final color = isLocation ? AppTheme.secondary : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        isLocation ? Icons.place_rounded : Icons.task_alt_rounded,
        size: 15,
        color: color,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeLabel = label.trim().isEmpty ? 'Không rõ' : label.trim();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              safeLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}