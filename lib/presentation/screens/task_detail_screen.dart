import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends ConsumerWidget {
  final TaskModel task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatReminder(int minutes) {
    switch (minutes) {
      case 0:
        return 'Không nhắc';
      case -1:
        return 'Demo sau 10 giây';
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
        return 'Trước $minutes phút';
    }
  }

  Uri _buildGoogleMapsUri() {
    final customUrl = task.googleMapsUrl?.trim();

    if (customUrl != null && customUrl.isNotEmpty) {
      return Uri.parse(customUrl);
    }

    final query = [
      task.locationName,
      task.locationAddress,
    ].where((item) => item != null && item.trim().isNotEmpty).join(' ');

    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final uri = _buildGoogleMapsUri();

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở Google Maps'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở Google Maps: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocationTask = task.isLocationTask;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isLocationTask
                          ? Icons.place_rounded
                          : Icons.task_alt_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLocationTask
                              ? 'Task có địa điểm'
                              : 'Task thông thường',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Mô tả',
              children: [
                Text(
                  task.description.trim(),
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          if (isLocationTask) ...[
            _InfoCard(
              title: 'Thời gian',
              children: [
                _InfoRow(
                  icon: Icons.play_circle_rounded,
                  label: 'Bắt đầu',
                  value: task.startTime == null
                      ? 'Chưa có'
                      : _formatDateTime(task.startTime!),
                ),
                _InfoRow(
                  icon: Icons.stop_circle_rounded,
                  label: 'Kết thúc',
                  value: task.endTime == null
                      ? 'Chưa có'
                      : _formatDateTime(task.endTime!),
                ),
                _InfoRow(
                  icon: Icons.notifications_active_rounded,
                  label: 'Nhắc trước',
                  value: _formatReminder(task.reminderMinutes),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Địa điểm',
              children: [
                _InfoRow(
                  icon: Icons.place_rounded,
                  label: 'Tên',
                  value: task.locationName?.trim().isNotEmpty == true
                      ? task.locationName!.trim()
                      : 'Chưa có',
                ),
                _InfoRow(
                  icon: Icons.location_city_rounded,
                  label: 'Địa chỉ',
                  value: task.locationAddress?.trim().isNotEmpty == true
                      ? task.locationAddress!.trim()
                      : 'Chưa có',
                ),
                _InfoRow(
                  icon: Icons.link_rounded,
                  label: 'Maps',
                  value: task.googleMapsUrl?.trim().isNotEmpty == true
                      ? 'Đã có link Google Maps'
                      : 'Tự tìm theo tên + địa chỉ',
                ),
              ],
            ),
            if (task.effectiveDestination != 'Điểm đến') ...[
              const SizedBox(height: 12),
              ref.watch(destinationWeatherProvider(task.effectiveDestination)).when(
                data: (weather) {
                  final rec = _getWeatherRecommendation(
                    weather.temperature,
                    weather.description,
                    weather.humidity,
                    weather.windSpeed,
                  );
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thời tiết tại điểm đến',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: scheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  weather.cityName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getWeatherIcon(weather.icon),
                                  color: scheme.primary,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${weather.temperature.toStringAsFixed(0)}°C • ${weather.description}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Độ ẩm: ${weather.humidity}% • Gió: ${weather.windSpeed.toStringAsFixed(1)} m/s',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: scheme.outlineVariant.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'Gợi ý chuẩn bị & di chuyển',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rec,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, color: scheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Không thể tải thông tin thời tiết tại ${task.effectiveDestination}. Vui lòng kiểm tra lại mạng hoặc tên điểm đến.',
                            style: TextStyle(color: scheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openGoogleMaps(context),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Mở Google Maps'),
            ),
          ] else ...[
            _InfoCard(
              title: 'Deadline',
              children: [
                _InfoRow(
                  icon: Icons.event_rounded,
                  label: 'Hạn',
                  value: _formatDateTime(task.deadline),
                ),
                _InfoRow(
                  icon: Icons.notifications_active_rounded,
                  label: 'Nhắc trước',
                  value: _formatReminder(task.reminderMinutes),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          _InfoCard(
            title: 'Thông tin khác',
            children: [
              _InfoRow(
                icon: Icons.flag_rounded,
                label: 'Ưu tiên',
                value: task.priority.label,
              ),
              _InfoRow(
                icon: Icons.sell_rounded,
                label: 'Tag',
                value: task.tag,
              ),
              _InfoRow(
                icon: task.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: 'Trạng thái',
                value: task.isDone ? 'Đã hoàn thành' : 'Chưa hoàn thành',
              ),
            ],
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

  String _getWeatherRecommendation(double temp, String desc, int humidity, double windSpeed) {
    final lowerDesc = desc.toLowerCase();
    String prep = '';
    String travel = '';

    if (lowerDesc.contains('mưa') || lowerDesc.contains('dông') || lowerDesc.contains('phùn') || lowerDesc.contains('bão')) {
      prep = 'Mang theo áo mưa hoặc ô (dù), mang giày chống nước.';
      travel = 'Đường trơn trượt tầm nhìn hạn chế, hãy di chuyển chậm và chú ý quan sát!';
    } else if (temp > 33) {
      prep = 'Mặc áo chống nắng, đội mũ, đeo kính râm và mang sẵn chai nước.';
      travel = 'Trời nắng nóng gay gắt, nên di chuyển bằng phương tiện mát mẻ hoặc tránh khung giờ nắng đỉnh điểm nếu có thể.';
    } else if (windSpeed > 8) {
      prep = 'Mặc áo khoác chắn gió, bảo vệ mắt khỏi bụi bẩn.';
      travel = 'Gió thổi mạnh, cẩn thận rung lắc tay lái, tránh đi gần cây lớn hoặc biển quảng cáo!';
    } else if (temp < 18) {
      prep = 'Mặc ấm, quàng khăn len để bảo vệ cổ họng.';
      travel = 'Thời tiết lạnh ráo, di chuyển chú ý giữ nhiệt cơ thể.';
    } else {
      prep = 'Trang phục thoải mái, mang theo một chai nước nhỏ.';
      travel = 'Thời tiết rất đẹp và mát mẻ, lý tưởng để di chuyển!';
    }

    return '• Chuẩn bị: $prep\n• Di chuyển: $travel';
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}