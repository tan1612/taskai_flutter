import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/utils/date_utils.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/task_provider.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
import 'package:taskai/presentation/screens/task_form_screen.dart';
import 'package:taskai/presentation/widgets/task_card.dart';
import 'package:taskai/presentation/widgets/weather_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(todayTasksProvider);
    final weather = ref.watch(weatherProvider);

    final done = todayTasks.where((e) => e.isDone).length;
    final total = todayTasks.length;
    final percent = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskAI',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại thời tiết',
            onPressed: () => ref.invalidate(weatherProvider),
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
        onRefresh: () async => ref.invalidate(weatherProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroSummary(
              total: total,
              done: done,
              percent: percent,
            ),
            const SizedBox(height: 14),
            weather.when(
              data: (data) => WeatherWidget(weather: data),
              loading: () => const _WeatherLoading(),
              error: (error, _) => _WeatherError(
                message: error.toString().replaceFirst('Exception: ', ''),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Công việc hôm nay',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(AppDateUtils.date(DateTime.now())),
              ],
            ),
            const SizedBox(height: 12),
            if (todayTasks.isEmpty)
              const _EmptyToday()
            else
              ...todayTasks.map(
                (task) => TaskCard(
                  task: task,
                  onToggle: () =>
                      ref.read(taskProvider.notifier).toggleDone(task),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(task: task),
                    ),
                  ),
                  onDelete: () =>
                      ref.read(taskProvider.notifier).delete(task.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final int total;
  final int done;
  final double percent;

  const _HeroSummary({
    required this.total,
    required this.done,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào, hôm nay bạn đã sẵn sàng chưa?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text('Đã hoàn thành $done/$total công việc hôm nay.'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: percent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 14),
            Text('Đang tải thời tiết...'),
          ],
        ),
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  final String message;

  const _WeatherError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Hôm nay chưa có task nào',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tạo một công việc mới để TaskAI nhắc bạn đúng hạn.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
