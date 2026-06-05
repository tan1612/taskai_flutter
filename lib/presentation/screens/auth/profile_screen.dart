import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/providers/task_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final tasks = ref.watch(taskProvider);
    final scheme = Theme.of(context).colorScheme;

    final user = authState.user;

    final syncedCount = tasks.where((t) => t.syncStatus == 'synced').length;
    final syncingCount = tasks.where((t) => t.syncStatus == 'syncing').length;
    final failedCount = tasks.where((t) => t.syncStatus == 'failed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User Avatar & Name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Chế độ Guest (Ngoại tuyến)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user != null ? 'User ID: ${user.uid}' : 'Các task sẽ chỉ lưu offline trên thiết bị',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Cloud Sync Stats
          if (user != null) ...[
            Text(
              'Trạng thái đồng bộ đám mây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildSyncRow(
                      context,
                      Icons.cloud_done_rounded,
                      'Đã đồng bộ',
                      '$syncedCount',
                      AppTheme.success,
                    ),
                    const Divider(height: 24),
                    _buildSyncRow(
                      context,
                      Icons.sync_rounded,
                      'Đang đồng bộ',
                      '$syncingCount',
                      AppTheme.warning,
                    ),
                    const Divider(height: 24),
                    _buildSyncRow(
                      context,
                      Icons.cloud_off_rounded,
                      'Lỗi đồng bộ',
                      '$failedCount',
                      AppTheme.danger,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Actions
          if (user != null)
            FilledButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).logout();
                  ref.read(guestModeProvider.notifier).state = false;
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng xuất tài khoản.')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('ĐĂNG XUẤT'),
            )
          else
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Back to where we were (triggers Login flow)
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('ĐĂNG NHẬP / ĐĂNG KÝ'),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
