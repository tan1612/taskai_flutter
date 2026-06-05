import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/models/timetable_slot.dart';

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

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimetableSlotAdapter());
    }

    await Hive.openBox<TaskModel>(AppConstants.taskBox);
    await Hive.openBox<dynamic>(AppConstants.settingsBox);
    await Hive.openBox<TimetableSlot>(AppConstants.timetableBox);
  }

  Box<TaskModel> get taskBox => Hive.box<TaskModel>(AppConstants.taskBox);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(AppConstants.settingsBox);

  Box<TimetableSlot> get timetableBox => Hive.box<TimetableSlot>(AppConstants.timetableBox);
}