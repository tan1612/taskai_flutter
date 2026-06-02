import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/presentation/providers/task_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final doneByDay = List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return tasks.where((task) {
        return task.isDone &&
            task.deadline.year == day.year &&
            task.deadline.month == day.month &&
            task.deadline.day == day.day;
      }).length;
    });

    final totalDone = tasks.where((e) => e.isDone).length;
    final total = tasks.length;
    final ratio = total == 0 ? 0 : ((totalDone / total) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Tổng task',
                  value: '$total',
                  icon: Icons.assignment_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Hoàn thành',
                  value: '$ratio%',
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task hoàn thành trong tuần',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (doneByDay.reduce((a, b) => a > b ? a : b) + 2)
                            .toDouble(),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                            ),
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
                                const labels = [
                                  'T2',
                                  'T3',
                                  'T4',
                                  'T5',
                                  'T6',
                                  'T7',
                                  'CN'
                                ];
                                final index = value.toInt();
                                if (index < 0 || index >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(labels[index]),
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
                                width: 22,
                                borderRadius: BorderRadius.circular(8),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                total == 0
                    ? 'Chưa có dữ liệu. Hãy tạo task để xem thống kê.'
                    : 'Bạn đã hoàn thành $totalDone/$total task. Tiếp tục giữ nhịp nhé!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
