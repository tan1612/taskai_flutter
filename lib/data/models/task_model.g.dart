// GENERATED CODE - DO NOT MODIFY BY HAND
// Có thể generate lại bằng:
// flutter pub run build_runner build --delete-conflicting-outputs

part of 'task_model.dart';

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();

    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      deadline: fields[3] as DateTime,
      priority: fields[4] as TaskPriority? ?? TaskPriority.medium,
      tag: fields[5] as String? ?? 'Khác',
      isDone: fields[6] as bool? ?? false,
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      reminderMinutes: fields[8] as int? ?? 60,
      type: fields[9] as TaskType? ?? TaskType.normal,
      startTime: fields[10] as DateTime?,
      endTime: fields[11] as DateTime?,
      locationName: fields[12] as String?,
      locationAddress: fields[13] as String?,
      googleMapsUrl: fields[14] as String?,
      originName: fields[15] as String?,
      destinationName: fields[16] as String?,
      travelMinutes: fields[17] as int? ?? 30,
      departReminderMinutes: fields[18] as int? ?? 10,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.tag)
      ..writeByte(6)
      ..write(obj.isDone)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.reminderMinutes)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.startTime)
      ..writeByte(11)
      ..write(obj.endTime)
      ..writeByte(12)
      ..write(obj.locationName)
      ..writeByte(13)
      ..write(obj.locationAddress)
      ..writeByte(14)
      ..write(obj.googleMapsUrl)
      ..writeByte(15)
      ..write(obj.originName)
      ..writeByte(16)
      ..write(obj.destinationName)
      ..writeByte(17)
      ..write(obj.travelMinutes)
      ..writeByte(18)
      ..write(obj.departReminderMinutes);
  }
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 1;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.high;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.high:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.low:
        writer.writeByte(2);
        break;
    }
  }
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 2;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.normal;
      case 1:
        return TaskType.location;
      default:
        return TaskType.normal;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.normal:
        writer.writeByte(0);
        break;
      case TaskType.location:
        writer.writeByte(1);
        break;
    }
  }
}