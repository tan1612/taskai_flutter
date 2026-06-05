import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/services/email_service.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/screens/auth/profile_screen.dart';

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

  Future<void> _testWeeklyNotification(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationServiceProvider).scheduleWeeklyReminderTestAfter10Seconds();

      final user = ref.read(authNotifierProvider).user;
      bool emailSent = false;
      if (user != null && user.email != null) {
        emailSent = await EmailService.sendWeeklyPlanningEmailAlert(user.email!);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user != null
              ? (emailSent
                  ? 'Đã đặt thông báo thử sau 10s và gửi email test thành công!'
                  : 'Đã đặt thông báo thử sau 10s (gửi email test thất bại, kiểm tra .env).')
              : 'Đã đặt thông báo thử sau 10s. Để test email, vui lòng đăng nhập trước!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đặt thông báo thử: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationEnabledProvider);
    final weeklyReminderEnabled = ref.watch(weeklyReminderEnabledProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

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
            child: ListTile(
              leading: Icon(
                user != null ? Icons.account_circle_rounded : Icons.login_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                user != null ? 'Tài khoản cá nhân' : 'Đăng nhập / Đăng ký',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                user != null
                    ? (user.email ?? 'Đã đăng nhập')
                    : 'Đăng nhập để lưu và đồng bộ lịch trình Pro',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
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
            child: SwitchListTile(
              value: weeklyReminderEnabled,
              onChanged: (value) {
                ref.read(weeklyReminderEnabledProvider.notifier).toggle(value);
              },
              title: const Text(
                'Nhắc nhở tuần mới',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Thông báo vào 19h mỗi Chủ Nhật để lên kế hoạch tuần tới',
              ),
              secondary: const Icon(Icons.calendar_month_rounded),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text(
                'Test nhắc nhở hàng tuần',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Nhận thông báo lên lịch tuần mới sau 10 giây để kiểm tra',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _testWeeklyNotification(context, ref),
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