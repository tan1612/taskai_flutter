import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/repositories/cloud_task_repository.dart';
import 'package:taskai/data/repositories/task_repository.dart';
import 'package:taskai/data/services/email_service.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';

final _cloudTaskRepositoryProvider = Provider<CloudTaskRepository>((ref) {
  return CloudTaskRepository(FirebaseFirestore.instance);
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository repository;
  final Ref ref;
  StreamSubscription? _syncSubscription;

  TaskNotifier(this.repository, this.ref) : super(repository.getAll()) {
    _initSync();
  }

  void _initSync() {
    // Subscribe to authStateChanges and initialize task sync
    ref.listen<User?>(authStateProvider.select((v) => v.value), (prev, next) {
      _subscribeToUserTasks(next);
    }, fireImmediately: true);
  }

  void _subscribeToUserTasks(User? user) {
    _syncSubscription?.cancel();

    final userId = user?.uid;
    if (userId != null) {
      _checkAndSendWeeklyPlanningEmail();
    }

    final stream = ref.read(_cloudTaskRepositoryProvider).taskStream(userId: userId);

    _syncSubscription = stream.listen((snapshot) {
      _handleCloudSnapshot(snapshot, userId);
    }, onError: (e) {
      print('Lỗi đồng bộ realtime: $e');
    });
  }

  Future<void> _handleCloudSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String? userId,
  ) async {
    final cloudTasks = snapshot.docs
        .map((doc) => ref.read(_cloudTaskRepositoryProvider).fromDoc(doc))
        .toList();
    final cloudIds = cloudTasks.map((t) => t.id).toSet();

    final localTasks = repository.getAll();

    for (final cloudTask in cloudTasks) {
      final local = repository.getById(cloudTask.id);

      if (local == null) {
        final updatedTask = cloudTask.copyWith(syncStatus: 'synced', userId: userId);
        await repository.upsert(updatedTask);
        await _scheduleNotificationIfEnabled(updatedTask);
      } else {
        if (!_areTasksEqual(local, cloudTask) || local.syncStatus != 'synced') {
          if (local.syncStatus == 'syncing') {
            // Local is currently being written/uploaded, skip updating it.
            continue;
          }
          if (local.syncStatus == 'failed') {
            // Local has offline changes that failed to sync, retry upload in background.
            _syncTaskToCloud(local);
          } else {
            // Cloud has newer data, update local Hive
            final updatedTask = cloudTask.copyWith(syncStatus: 'synced', userId: userId);
            await repository.upsert(updatedTask);
            await _scheduleNotificationIfEnabled(updatedTask);
          }
        }
      }
    }

    // Check for deletions: if a task is 'synced' locally but not in cloud, delete it.
    for (final local in localTasks) {
      if (userId != null && local.userId != userId) {
        continue;
      }
      if (local.syncStatus == 'synced' && !cloudIds.contains(local.id)) {
        await repository.delete(local.id);
        try {
          await ref.read(notificationServiceProvider).cancelTaskReminder(local.id);
        } catch (e) {
          print('Lỗi hủy notification: $e');
        }
      }
    }

    state = repository.getAll();
  }

  bool _areTasksEqual(TaskModel a, TaskModel b) {
    return a.title == b.title &&
        a.description == b.description &&
        a.isDone == b.isDone &&
        a.tag == b.tag &&
        a.priority == b.priority &&
        a.deadline.isAtSameMomentAs(b.deadline) &&
        a.reminderMinutes == b.reminderMinutes &&
        a.type == b.type &&
        a.startTime == b.startTime &&
        a.endTime == b.endTime &&
        a.locationName == b.locationName &&
        a.locationAddress == b.locationAddress &&
        a.googleMapsUrl == b.googleMapsUrl &&
        a.travelMinutes == b.travelMinutes &&
        a.departReminderMinutes == b.departReminderMinutes;
  }

  Future<void> addOrUpdate(TaskModel task) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    final localTask = task.copyWith(syncStatus: 'syncing', userId: userId);

    await repository.upsert(localTask);
    state = repository.getAll();

    await _scheduleNotificationIfEnabled(localTask);

    _syncTaskToCloud(localTask);

    if (localTask.priority == TaskPriority.high) {
      final emailRecipient = user?.email ?? '';
      _sendEmailAlertInBackground(localTask, emailRecipient);
    }
  }

  Future<void> _sendEmailAlertInBackground(TaskModel task, String userEmail) async {
    try {
      await EmailService.sendHighPriorityTaskAlert(task, userEmail);
    } catch (e) {
      print('Lỗi gửi email cảnh báo: $e');
    }
  }

  Future<void> toggleDone(TaskModel task) async {
    final updated = task.copyWith(
      isDone: !task.isDone,
      syncStatus: 'syncing',
    );

    await repository.upsert(updated);
    state = repository.getAll();

    try {
      if (updated.isDone) {
        await ref.read(notificationServiceProvider).cancelTaskReminder(updated.id);
      } else {
        await _scheduleNotificationIfEnabled(updated);
      }
    } catch (e) {
      print('Lỗi cập nhật notification: $e');
    }

    _syncTaskToCloud(updated);
  }

  Future<void> delete(String id) async {
    final task = repository.getById(id);
    final userId = task?.userId ?? ref.read(authNotifierProvider).user?.uid;

    await repository.delete(id);
    state = repository.getAll();

    try {
      await ref.read(notificationServiceProvider).cancelTaskReminder(id);
    } catch (e) {
      print('Lỗi hủy notification: $e');
    }

    _deleteTaskFromCloud(id, userId);
  }

  List<TaskModel> tasksForDate(DateTime date) {
    return state.where((task) {
      final compareDate = task.isLocationTask && task.startTime != null
          ? task.startTime!
          : task.deadline;

      return compareDate.year == date.year &&
          compareDate.month == date.month &&
          compareDate.day == date.day;
    }).toList();
  }

  List<TaskModel> get unfinishedTasks {
    return state.where((task) => !task.isDone).toList();
  }

  List<TaskModel> get doneTasks {
    return state.where((task) => task.isDone).toList();
  }

  Future<void> _syncTaskToCloud(TaskModel task) async {
    final userId = ref.read(authNotifierProvider).user?.uid;
    try {
      await ref.read(_cloudTaskRepositoryProvider).upsert(task, userId: userId);
      final syncedTask = task.copyWith(syncStatus: 'synced', userId: userId);
      await repository.upsert(syncedTask);
      state = repository.getAll();
    } catch (e) {
      print('Không thể sync task lên Firestore: $e');
      final failedTask = task.copyWith(syncStatus: 'failed', userId: userId);
      await repository.upsert(failedTask);
      state = repository.getAll();
    }
  }

  Future<void> _deleteTaskFromCloud(String id, String? userId) async {
    try {
      await ref.read(_cloudTaskRepositoryProvider).delete(id, userId: userId);
    } catch (e) {
      print('Không thể xóa task trên Firestore: $e');
    }
  }

  Future<void> _checkAndSendWeeklyPlanningEmail() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null || user.email == null) return;

    final hiveService = ref.read(hiveServiceProvider);
    final weeklyEnabled = hiveService.settingsBox.get('weeklyReminderEnabled') as bool? ?? true;
    if (!weeklyEnabled) return;

    final now = DateTime.now();
    // Tìm Chủ nhật gần nhất trong quá khứ lúc 19:00
    DateTime lastSundaySevenPM = DateTime(now.year, now.month, now.day, 19, 0);
    while (lastSundaySevenPM.weekday != DateTime.sunday) {
      lastSundaySevenPM = lastSundaySevenPM.subtract(const Duration(days: 1));
    }
    if (lastSundaySevenPM.isAfter(now)) {
      lastSundaySevenPM = lastSundaySevenPM.subtract(const Duration(days: 7));
    }

    final lastSentStr = hiveService.settingsBox.get('lastWeeklyEmailSentTimestamp') as String?;
    if (lastSentStr == null) {
      // Lần đầu tiên, ta đánh dấu đã gửi cho Chủ nhật trước đó để tránh gửi email ngay lập tức khi đăng nhập
      await hiveService.settingsBox.put('lastWeeklyEmailSentTimestamp', lastSundaySevenPM.toIso8601String());
      return;
    }

    final lastSent = DateTime.parse(lastSentStr);
    if (lastSent.isBefore(lastSundaySevenPM)) {
      // Đã qua 19h Chủ nhật mới mà chưa gửi email, tiến hành gửi
      final success = await EmailService.sendWeeklyPlanningEmailAlert(user.email!);
      if (success) {
        await hiveService.settingsBox.put('lastWeeklyEmailSentTimestamp', lastSundaySevenPM.toIso8601String());
      }
    }
  }

  Future<void> _scheduleNotificationIfEnabled(TaskModel task) async {
    final notificationsEnabled = ref.read(notificationEnabledProvider);
    if (notificationsEnabled || task.reminderMinutes == -1) {
      try {
        await ref.read(notificationServiceProvider).cancelTaskReminder(task.id);
        await ref.read(notificationServiceProvider).scheduleTaskReminder(task);
      } catch (e) {
        print('Lỗi đặt notification: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  return TaskNotifier(ref.watch(taskRepositoryProvider), ref);
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final now = DateTime.now();

  return ref.watch(taskProvider).where((task) {
    final compareDate = task.isLocationTask && task.startTime != null
        ? task.startTime!
        : task.deadline;

    return compareDate.year == now.year &&
        compareDate.month == now.month &&
        compareDate.day == now.day;
  }).toList();
});

final unfinishedTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(taskProvider).where((task) => !task.isDone).toList();
});

final doneTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(taskProvider).where((task) => task.isDone).toList();
});

final tagsProvider = Provider<List<String>>((ref) {
  final tasks = ref.watch(taskProvider);

  final tags = tasks
      .map((task) => task.tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();

  tags.sort();

  return ['Tất cả', ...tags];
});