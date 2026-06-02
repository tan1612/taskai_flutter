import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/repositories/cloud_task_repository.dart';
import 'package:taskai/data/repositories/task_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';

final _cloudTaskRepositoryProvider = Provider<CloudTaskRepository>((ref) {
  return CloudTaskRepository(FirebaseFirestore.instance);
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository repository;
  final Ref ref;

  TaskNotifier(this.repository, this.ref) : super(repository.getAll());

  Future<void> addOrUpdate(TaskModel task) async {
    await repository.upsert(task);
    state = repository.getAll();

    await _syncTaskToCloud(task);

    final notificationsEnabled = ref.read(notificationEnabledProvider);

    if (notificationsEnabled) {
      try {
        await ref.read(notificationServiceProvider).cancelTaskReminder(task.id);
        await ref.read(notificationServiceProvider).scheduleTaskReminder(task);
      } catch (e) {
        print('Lỗi đặt notification: $e');
      }
    }
  }

  Future<void> toggleDone(TaskModel task) async {
    final updated = task.copyWith(isDone: !task.isDone);

    await repository.upsert(updated);
    state = repository.getAll();

    await _syncTaskToCloud(updated);

    try {
      if (updated.isDone) {
        await ref.read(notificationServiceProvider).cancelTaskReminder(updated.id);
      } else {
        final notificationsEnabled = ref.read(notificationEnabledProvider);

        if (notificationsEnabled) {
          await ref
              .read(notificationServiceProvider)
              .cancelTaskReminder(updated.id);

          await ref
              .read(notificationServiceProvider)
              .scheduleTaskReminder(updated);
        }
      }
    } catch (e) {
      print('Lỗi cập nhật notification: $e');
    }
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    state = repository.getAll();

    try {
      await ref.read(notificationServiceProvider).cancelTaskReminder(id);
    } catch (e) {
      print('Lỗi hủy notification: $e');
    }

    await _deleteTaskFromCloud(id);
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
    try {
      await ref.read(_cloudTaskRepositoryProvider).upsert(task);
      print('Đã sync task "${task.title}" lên Firestore');
    } catch (e) {
      print('Không thể sync task lên Firestore: $e');
    }
  }

  Future<void> _deleteTaskFromCloud(String id) async {
    try {
      await ref.read(_cloudTaskRepositoryProvider).delete(id);
      print('Đã xóa task $id trên Firestore');
    } catch (e) {
      print('Không thể xóa task trên Firestore: $e');
    }
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