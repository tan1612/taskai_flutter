import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/task_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  // Helper to calculate overdue tasks
  List<TaskModel> _getOverdueTasks(List<TaskModel> tasks, DateTime now) {
    return tasks.where((t) {
      if (t.isDone) return false;
      final tTime = t.isLocationTask && t.startTime != null ? t.startTime! : t.deadline;
      return tTime.isBefore(now);
    }).toList();
  }

  // Smart advice generator based on overdue tags
  String _getSmartSuggestion(List<TaskModel> tasks, DateTime now) {
    final overdue = _getOverdueTasks(tasks, now);
    if (overdue.isEmpty) {
      return '🎉 Tuyệt vời! Bạn đang kiểm soát lịch trình rất tốt và không trễ hạn task nào. Hãy duy trì nhé!';
    }

    // Count overdue by tag
    final tagCount = <String, int>{};
    for (final t in overdue) {
      final tag = t.tag.trim().isEmpty ? 'Khác' : t.tag.trim();
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }

    if (tagCount.isEmpty) {
      return '⚠️ Bạn có vài công việc trễ hạn. Hãy chia nhỏ công việc và đặt lịch nhắc sớm hơn!';
    }

    // Find tag with most overdue
    var worstTag = tagCount.keys.first;
    var maxOverdue = tagCount[worstTag]!;
    tagCount.forEach((tag, count) {
      if (count > maxOverdue) {
        maxOverdue = count;
        worstTag = tag;
      }
    });

    return '⚠️ Bạn thường trễ các task thuộc nhóm **"$worstTag"** ($maxOverdue task trễ). Bạn nên bật chế độ nhắc nhở trước 15-30 phút đối với nhóm này!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final now = DateTime.now();

    // Stats calculations
    final total = tasks.length;
    final totalDone = tasks.where((e) => e.isDone).length;
    final totalPending = total - totalDone;
    final overdueTasks = _getOverdueTasks(tasks, now);
    final totalOverdue = overdueTasks.length;
    final ratio = total == 0 ? 0 : ((totalDone / total) * 100).round();

    // 7-day completion chart data (last 7 days dynamically)
    final last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    final doneByDay = last7Days.map((day) {
      return tasks.where((task) {
        return task.isDone &&
            task.deadline.year == day.year &&
            task.deadline.month == day.month &&
            task.deadline.day == day.day;
      }).length;
    }).toList();

    // Priority breakdown
    final highTasks = tasks.where((t) => t.priority == TaskPriority.high).toList();
    final highDone = highTasks.where((t) => t.isDone).length;
    final highRatio = highTasks.isEmpty ? 0.0 : highDone / highTasks.length;

    final medTasks = tasks.where((t) => t.priority == TaskPriority.medium).toList();
    final medDone = medTasks.where((t) => t.isDone).length;
    final medRatio = medTasks.isEmpty ? 0.0 : medDone / medTasks.length;

    final lowTasks = tasks.where((t) => t.priority == TaskPriority.low).toList();
    final lowDone = lowTasks.where((t) => t.isDone).length;
    final lowRatio = lowTasks.isEmpty ? 0.0 : lowDone / lowTasks.length;

    // Tag breakdown
    final tagsMap = <String, List<TaskModel>>{};
    for (final t in tasks) {
      final tag = t.tag.trim().isEmpty ? 'Khác' : t.tag.trim();
      tagsMap.putIfAbsent(tag, () => []).add(t);
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê & Phân tích',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row of stats cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _MetricCard(
                title: 'Tổng công việc',
                value: '$total',
                icon: Icons.assignment_rounded,
                color: scheme.primary,
              ),
              _MetricCard(
                title: 'Hoàn thành',
                value: '$ratio%',
                icon: Icons.verified_rounded,
                color: AppTheme.success,
              ),
              _MetricCard(
                title: 'Chưa làm',
                value: '$totalPending',
                icon: Icons.pending_actions_rounded,
                color: AppTheme.warning,
              ),
              _MetricCard(
                title: 'Trễ hạn',
                value: '$totalOverdue',
                icon: Icons.error_outline_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smart recommendations card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: AppTheme.warning, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Lời khuyên từ AI Trợ Lý',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getSmartSuggestion(tasks, now),
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7-day completion chart
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiến độ 7 ngày gần nhất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số task hoàn thành theo ngày',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (doneByDay.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= last7Days.length) {
                                  return const SizedBox.shrink();
                                }
                                final dayStr = DateFormat('dd/MM').format(last7Days[index]);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayStr,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(
                          7,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: doneByDay[index].toDouble(),
                                color: scheme.primary,
                                width: 16,
                                borderRadius: BorderRadius.circular(6),
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
          ),
          const SizedBox(height: 16),

          // Priority Progress Breakdown
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoàn thành theo mức độ ưu tiên',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  _buildPriorityProgressBar(
                    'Mức độ: Cao (High)',
                    '${highDone}/${highTasks.length} task',
                    highRatio,
                    AppTheme.danger,
                  ),
                  const SizedBox(height: 14),
                  _buildPriorityProgressBar(
                    'Mức độ: Trung bình (Medium)',
                    '${medDone}/${medTasks.length} task',
                    medRatio,
                    AppTheme.warning,
                  ),
                  const SizedBox(height: 14),
                  _buildPriorityProgressBar(
                    'Mức độ: Thấp (Low)',
                    '${lowDone}/${lowTasks.length} task',
                    lowRatio,
                    AppTheme.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tag breakdown progress list
          if (tagsMap.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỷ lệ hoàn thành theo Tag',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    ...tagsMap.entries.map((entry) {
                      final tag = entry.key;
                      final tagTasks = entry.value;
                      final tagDone = tagTasks.where((t) => t.isDone).length;
                      final tagRatio = tagTasks.isEmpty ? 0.0 : tagDone / tagTasks.length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPriorityProgressBar(
                          tag,
                          '${tagDone}/${tagTasks.length} task',
                          tagRatio,
                          scheme.secondary,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 100), // padding bottom
        ],
      ),
    );
  }

  Widget _buildPriorityProgressBar(
    String label,
    String countLabel,
    double ratio,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              countLabel,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
