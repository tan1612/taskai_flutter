import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/repositories/cloud_task_repository.dart';
import 'package:taskai/data/repositories/cloud_timetable_repository.dart';
import 'package:taskai/data/repositories/gemini_repository.dart';
import 'package:taskai/data/repositories/task_repository.dart';
import 'package:taskai/data/repositories/timetable_repository.dart';
import 'package:taskai/data/repositories/weather_repository.dart';
import 'package:taskai/data/services/api_service.dart';
import 'package:taskai/data/services/hive_service.dart';
import 'package:taskai/data/services/notification_service.dart';

// Export để các file khác chỉ cần import app_providers.dart là dùng được hết
export 'package:taskai/presentation/providers/task_provider.dart';
export 'package:taskai/presentation/providers/weather_provider.dart';
export 'package:taskai/presentation/providers/timetable_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return TaskRepository(hive.taskBox);
});

final cloudTaskRepositoryProvider = Provider<CloudTaskRepository>((ref) {
  return CloudTaskRepository(ref.watch(firestoreProvider));
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return TimetableRepository(hive.timetableBox);
});

final cloudTimetableRepositoryProvider = Provider<CloudTimetableRepository>((ref) {
  return CloudTimetableRepository(ref.watch(firestoreProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.watch(apiServiceProvider));
});

final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepository(ref.watch(apiServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HiveService hiveService;

  ThemeModeNotifier(this.hiveService)
      : super(
          (hiveService.settingsBox.get('themeMode') as String?) == 'dark'
              ? ThemeMode.dark
              : ThemeMode.light,
        );

  void toggle(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    hiveService.settingsBox.put('themeMode', isDark ? 'dark' : 'light');
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(hiveServiceProvider));
});

class NotificationEnabledNotifier extends StateNotifier<bool> {
  final HiveService hiveService;

  NotificationEnabledNotifier(this.hiveService)
      : super(
          hiveService.settingsBox.get('notificationsEnabled') as bool? ?? true,
        );

  void toggle(bool enabled) {
    state = enabled;
    hiveService.settingsBox.put('notificationsEnabled', enabled);
  }
}

final notificationEnabledProvider =
    StateNotifierProvider<NotificationEnabledNotifier, bool>((ref) {
  return NotificationEnabledNotifier(ref.watch(hiveServiceProvider));
});

class WeeklyReminderEnabledNotifier extends StateNotifier<bool> {
  final HiveService hiveService;
  final NotificationService notificationService;

  WeeklyReminderEnabledNotifier(this.hiveService, this.notificationService)
      : super(
          hiveService.settingsBox.get('weeklyReminderEnabled') as bool? ?? true,
        );

  Future<void> toggle(bool enabled) async {
    state = enabled;
    await hiveService.settingsBox.put('weeklyReminderEnabled', enabled);
    if (enabled) {
      try {
        await notificationService.scheduleWeeklySundayReminder();
      } catch (e) {
        debugPrint('Lỗi đặt nhắc nhở hàng tuần: $e');
      }
    } else {
      try {
        await notificationService.cancelWeeklySundayReminder();
      } catch (e) {
        debugPrint('Lỗi hủy nhắc nhở hàng tuần: $e');
      }
    }
  }
}

final weeklyReminderEnabledProvider =
    StateNotifierProvider<WeeklyReminderEnabledNotifier, bool>((ref) {
  return WeeklyReminderEnabledNotifier(
    ref.watch(hiveServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});