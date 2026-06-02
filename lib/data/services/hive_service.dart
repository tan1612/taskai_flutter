import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/data/models/task_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }

    // BẮT BUỘC: đăng ký adapter cho TaskType
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskTypeAdapter());
    }

    await Hive.openBox<TaskModel>(AppConstants.taskBox);
    await Hive.openBox<dynamic>(AppConstants.settingsBox);
  }

  Box<TaskModel> get taskBox => Hive.box<TaskModel>(AppConstants.taskBox);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(AppConstants.settingsBox);
}