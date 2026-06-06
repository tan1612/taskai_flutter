import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
import 'package:taskai/presentation/screens/task_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskCard extends ConsumerWidget {
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

  String get _reminderLabel {
    switch (task.reminderMinutes) {
      case 0:
        return 'Không nhắc';
      case -1:
        return 'Demo 10s';
      case 5:
        return 'Trước 5 phút';
      case 10:
        return 'Trước 10 phút';
      case 15:
        return 'Trước 15 phút';
      case 30:
        return 'Trước 30 phút';
      case 60:
        return 'Trước 1 tiếng';
      case 1440:
        return 'Trước 1 ngày';
      default:
        return 'Nhắc trước ${task.reminderMinutes} phút';
    }
  }

  Future<void> _openMaps() async {
    if (task.googleMapsUrl == null || task.googleMapsUrl!.trim().isEmpty) return;
    final uri = Uri.tryParse(task.googleMapsUrl!.trim());
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Không thể mở Google Maps: $e');
      }
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 16,
      decoration: task.isDone ? TextDecoration.lineThrough : null,
      color: task.isDone ? scheme.onSurface.withOpacity(0.4) : scheme.onSurface,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color indicator for priority
                Container(
                  width: 5,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Done checkbox
                Checkbox(
                  value: task.isDone,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),

                // Main Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Tag
                          if (task.tag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _priorityColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag_rounded, size: 12, color: _priorityColor),
                                const SizedBox(width: 3),
                                Text(
                                  task.priority.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sync Status
                          if (task.syncStatus != 'synced')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (task.syncStatus == 'failed' ? AppTheme.danger : AppTheme.warning).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    task.syncStatus == 'failed' ? Icons.sync_problem_rounded : Icons.sync_rounded,
                                    size: 12,
                                    color: task.syncStatus == 'failed' ? AppTheme.danger : AppTheme.warning,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.syncStatus == 'failed' ? 'Lỗi sync' : 'Đang sync',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: task.syncStatus == 'failed' ? AppTheme.danger : AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        task.title,
                        style: titleStyle,
                      ),

                      // Description
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Di chuyển vs. Normal specifics
                      if (task.isLocationTask) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Departure -> Destination
                              Row(
                                children: [
                                  Icon(Icons.directions_walk_rounded, size: 16, color: scheme.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${task.effectiveOrigin} → ${task.effectiveDestination}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Location name and address
                              if (task.locationName != null && task.locationName!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.place_rounded, size: 14, color: scheme.secondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${task.locationName} (${task.locationAddress ?? ""})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Travel Time & Departure Info
                              Row(
                                children: [
                                  Icon(Icons.directions_car_rounded, size: 14, color: scheme.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Di chuyển: ${task.travelMinutes} phút',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (task.effectiveDestination != 'Điểm đến') ...[
                                ref.watch(destinationWeatherProvider(task.effectiveDestination)).when(
                                  data: (weather) => Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getWeatherIcon(weather.icon),
                                          size: 14,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Thời tiết điểm đến: ${weather.temperature.toStringAsFixed(0)}°C, ${weather.description}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  loading: () => const Padding(
                                    padding: EdgeInsets.only(top: 6.0),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ),
                                  error: (err, _) => const SizedBox.shrink(),
                                ),
                              ],
                              const SizedBox(height: 6),
                              
                              // Departure Time and Start Time
                              if (task.departureTime != null && task.startTime != null) ...[
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.alarm_rounded, size: 14, color: AppTheme.secondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Xuất phát: ',
                                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                        Text(
                                          _formatTime(task.departureTime!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_circle_outline_rounded, size: 14, color: scheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Vào học/lịch: ',
                                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                        Text(
                                          _formatTime(task.startTime!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              
                              // Google Maps Action
                              if (task.googleMapsUrl != null && task.googleMapsUrl!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: _openMaps,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map_rounded, size: 14, color: scheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chỉ đường Google Maps',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        // Normal Task deadline
                        Row(
                          children: [
                            Icon(Icons.event_note_rounded, size: 15, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Hạn chót: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDateTime(task.deadline),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Notification Mode
                      Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, size: 13, color: scheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 6),
                          Text(
                            _reminderLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing actions (Popup menu)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'detail') {
                      _openDetail(context);
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded),
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
                          Icon(Icons.delete_rounded, color: AppTheme.danger),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: AppTheme.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny_rounded;
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Icons.wb_cloudy_rounded;
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.umbrella_rounded;
    if (iconCode.startsWith('11')) return Icons.thunderstorm_rounded;
    if (iconCode.startsWith('13')) return Icons.ac_unit_rounded;
    return Icons.filter_drama_rounded;
  }
}