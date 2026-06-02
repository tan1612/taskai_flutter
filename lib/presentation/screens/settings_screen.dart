import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/presentation/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _testNotification(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationServiceProvider).showTestNotification();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo thử. Hãy kéo thanh thông báo xuống để kiểm tra.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi thông báo thử: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggle(value);
              },
              title: const Text(
                'Giao diện tối',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Bật/tắt dark mode cho toàn app'),
              secondary: const Icon(Icons.dark_mode_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: notificationsEnabled,
              onChanged: (value) {
                ref.read(notificationEnabledProvider.notifier).toggle(value);
              },
              title: const Text(
                'Notification',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Bật/tắt nhắc deadline'),
              secondary: const Icon(Icons.notifications_active_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notification_add_rounded),
              title: const Text(
                'Test thông báo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Bấm để kiểm tra notification trên Android/emulator',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _testNotification(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'API key được lưu trong file .env: GEMINI/GROQ API key và OPENWEATHER_API_KEY.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}