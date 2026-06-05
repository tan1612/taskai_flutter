import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/core/utils/date_utils.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/models/weather_model.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/providers/task_provider.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
import 'package:taskai/presentation/screens/task_form_screen.dart';
import 'package:taskai/presentation/widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Helper to choose smart suggestion based on weather
  String _getWeatherRecommendation(WeatherModel weather) {
    final desc = weather.description.toLowerCase();
    final temp = weather.temperature;
    final wind = weather.windSpeed;

    if (desc.contains('mưa') || desc.contains('dông') || desc.contains('phùn')) {
      return 'Nên mang áo mưa hoặc mang ô che mưa khi ra ngoài! 🌧️';
    }
    if (temp > 33) {
      return 'Trời nắng nóng gay gắt. Nhớ mang theo nước và kem chống nắng! ☀️';
    }
    if (wind > 8) {
      return 'Trời có gió mạnh. Hãy cẩn thận khi lái xe di chuyển! 💨';
    }
    return 'Thời tiết hôm nay rất đẹp, thích hợp để học tập và đi lại! 🌟';
  }

  // Find the smartest task to do first: high priority and closest deadline
  TaskModel? _getSmartRecommendation(List<TaskModel> tasks) {
    final pending = tasks.where((t) => !t.isDone).toList();
    if (pending.isEmpty) return null;

    pending.sort((a, b) {
      // High priority first
      final pCompare = b.priority.weight.compareTo(a.priority.weight);
      if (pCompare != 0) return pCompare;

      // Closest deadline first
      final aTime = a.isLocationTask && a.startTime != null ? a.startTime! : a.deadline;
      final bTime = b.isLocationTask && b.startTime != null ? b.startTime! : b.deadline;
      return aTime.compareTo(bTime);
    });

    return pending.first;
  }

  // Find the absolute nearest task (over all tasks, not just today)
  TaskModel? _getNearestTask(List<TaskModel> allTasks) {
    final pending = allTasks.where((t) => !t.isDone).toList();
    if (pending.isEmpty) return null;

    pending.sort((a, b) {
      final aTime = a.isLocationTask && a.startTime != null ? a.startTime! : a.deadline;
      final bTime = b.isLocationTask && b.startTime != null ? b.startTime! : b.deadline;
      return aTime.compareTo(bTime);
    });

    return pending.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(todayTasksProvider);
    final allTasks = ref.watch(taskProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final forecastAsync = ref.watch(forecastWeatherProvider);
    final authState = ref.watch(authNotifierProvider);

    final done = todayTasks.where((e) => e.isDone).length;
    final total = todayTasks.length;
    final percent = total == 0 ? 0.0 : done / total;

    // Smart recommendations
    final smartRec = _getSmartRecommendation(todayTasks);
    final nearestTask = _getNearestTask(allTasks);

    final userName = authState.user != null
        ? (authState.user!.email!.split('@')[0])
        : 'Sinh Viên';

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TaskAI Pro',
          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: () {
              ref.invalidate(weatherProvider);
              ref.invalidate(forecastWeatherProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo task'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(forecastWeatherProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome & Progress Hero Banner
            _HeroSummary(
              userName: userName,
              total: total,
              done: done,
              percent: percent,
            ),
            const SizedBox(height: 16),

            // Combined Weather Card (Current + Forecast)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời tiết & Di chuyển',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    weatherAsync.when(
                      data: (weather) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentWeatherRow(context, weather),
                          const SizedBox(height: 12),
                          // Smart Tip Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tips_and_updates_rounded, color: scheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getWeatherRecommendation(weather),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Lỗi tải thời tiết hiện tại: $err'),
                    ),
                    
                    // Forecast 3-hour chunks
                    const SizedBox(height: 16),
                    Text(
                      'Dự báo vài giờ tới',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    forecastAsync.when(
                      data: (forecast) => SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: forecast.items.take(6).length,
                          itemBuilder: (context, idx) {
                            final item = forecast.items[idx];
                            return _buildForecastTile(context, item);
                          },
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Lỗi tải dự báo: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Smart Recommendation: "Việc nên làm trước"
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppTheme.warning, size: 20),
                        const SizedBox(width: 6),
                        const Text(
                          'Gợi ý thông minh: Việc nên làm trước',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (smartRec != null)
                      _buildSuggestedTaskCard(context, smartRec, ref)
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '🎉 Tuyệt vời! Bạn không còn công việc nào chưa hoàn thành hôm nay.',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sắp đến hạn gần nhất
            if (nearestTask != null && (smartRec == null || nearestTask.id != smartRec.id)) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⏰ Công việc sắp đến hạn gần nhất',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      TaskCard(
                        task: nearestTask,
                        onToggle: () => ref.read(taskProvider.notifier).toggleDone(nearestTask),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskFormScreen(task: nearestTask)),
                        ),
                        onDelete: () => ref.read(taskProvider.notifier).delete(nearestTask.id),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Daily Task List header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Công việc hôm nay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  AppDateUtils.date(DateTime.now()),
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tasks List
            if (todayTasks.isEmpty)
              const _EmptyToday()
            else
              ...todayTasks.map(
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
            const SizedBox(height: 80), // spacer for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherRow(BuildContext context, WeatherModel weather) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getWeatherIcon(weather.icon),
            color: scheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.cityName} • ${weather.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                '${weather.description[0].toUpperCase()}${weather.description.substring(1)}',
                style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.65), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Độ ẩm: ${weather.humidity}% • Gió: ${weather.windSpeed.toStringAsFixed(1)} m/s',
                style: TextStyle(fontSize: 11.5, color: scheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastTile(BuildContext context, ForecastWeatherItem item) {
    final scheme = Theme.of(context).colorScheme;
    final hour = '${item.time.hour.toString().padLeft(2, '0')}:00';
    
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hour,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Icon(_getWeatherIcon(item.icon), size: 20, color: scheme.primary),
          const SizedBox(height: 4),
          Text(
            '${item.temperature.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
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

  Widget _buildSuggestedTaskCard(BuildContext context, TaskModel task, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final priorityColor = task.priority == TaskPriority.high
        ? AppTheme.danger
        : (task.priority == TaskPriority.medium ? AppTheme.warning : AppTheme.success);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.check_circle_outline_rounded, color: priorityColor),
                onPressed: () => ref.read(taskProvider.notifier).toggleDone(task),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.description.isEmpty ? 'Không có mô tả.' : task.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: priorityColor),
              const SizedBox(width: 4),
              Text(
                'Độ ưu tiên: ${task.priority.label}',
                style: TextStyle(fontSize: 11.5, color: priorityColor, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                task.isLocationTask && task.startTime != null
                    ? 'Xuất phát lúc: ${_formatTime(task.departureTime!)}'
                    : 'Hạn chót: ${AppDateUtils.dateTime(task.deadline)}',
                style: TextStyle(fontSize: 11.5, color: scheme.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime val) {
    return '${val.hour.toString().padLeft(2, '0')}:${val.minute.toString().padLeft(2, '0')}';
  }
}

class _HeroSummary extends StatelessWidget {
  final String userName;
  final int total;
  final int done;
  final double percent;

  const _HeroSummary({
    required this.userName,
    required this.total,
    required this.done,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.95),
            scheme.secondary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào $userName 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'Bạn chưa có việc nào trong hôm nay.'
                        : 'Bạn đã hoàn thành $done/$total công việc hôm nay.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Circular progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: scheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hôm nay chưa có task nào',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Tạo một công việc mới để TaskAI nhắc nhở bạn đúng hạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
