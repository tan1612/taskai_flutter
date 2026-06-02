import 'package:hive/hive.dart';
import 'package:taskai/data/models/task_model.dart';

class TaskRepository {
  final Box<TaskModel> _box;

  TaskRepository(this._box);

  List<TaskModel> getAll() {
    final tasks = _box.values.toList();

    tasks.sort((a, b) {
      final byDone = a.isDone == b.isDone ? 0 : (a.isDone ? 1 : -1);
      if (byDone != 0) return byDone;

      final byDeadline = a.deadline.compareTo(b.deadline);
      if (byDeadline != 0) return byDeadline;

      return b.priority.weight.compareTo(a.priority.weight);
    });

    return tasks;
  }

  Future<void> upsert(TaskModel task) async {
    await _box.put(task.id, task);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  TaskModel? getById(String id) {
    return _box.get(id);
  }
}