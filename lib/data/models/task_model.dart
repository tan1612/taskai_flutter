import 'package:hive/hive.dart';

enum TaskPriority {
  high,
  medium,
  low,
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.low:
        return 'Thấp';
    }
  }

  int get weight {
    switch (this) {
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  int get sortWeight => weight;
}

enum TaskType {
  normal,
  location,
}

extension TaskTypeX on TaskType {
  String get label {
    switch (this) {
      case TaskType.normal:
        return 'Thông thường';
      case TaskType.location:
        return 'Có di chuyển';
    }
  }
}

class TaskModel extends HiveObject {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final String tag;
  final bool isDone;
  final DateTime createdAt;
  final int reminderMinutes;
  final TaskType type;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? locationName;
  final String? locationAddress;
  final String? googleMapsUrl;
  final String? originName;
  final String? destinationName;
  final int travelMinutes;
  final int departReminderMinutes;
  final String? syncStatus; // 'synced', 'syncing', 'failed'
  final String? userId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.tag,
    required this.isDone,
    required this.createdAt,
    this.reminderMinutes = 60,
    this.type = TaskType.normal,
    this.startTime,
    this.endTime,
    this.locationName,
    this.locationAddress,
    this.googleMapsUrl,
    this.originName,
    this.destinationName,
    this.travelMinutes = 30,
    this.departReminderMinutes = 10,
    this.syncStatus = 'synced',
    this.userId,
  });

  bool get isLocationTask => type == TaskType.location;

  bool get hasLocationInfo {
    return isLocationTask &&
        ((locationName != null && locationName!.trim().isNotEmpty) ||
            (locationAddress != null && locationAddress!.trim().isNotEmpty) ||
            (originName != null && originName!.trim().isNotEmpty) ||
            (destinationName != null && destinationName!.trim().isNotEmpty) ||
            (googleMapsUrl != null && googleMapsUrl!.trim().isNotEmpty));
  }

  String get effectiveOrigin {
    final origin = originName?.trim() ?? '';
    return origin.isNotEmpty ? origin : 'Điểm đi';
  }

  String get effectiveDestination {
    final destination = destinationName?.trim() ?? '';
    if (destination.isNotEmpty) return destination;

    final oldLocation = locationName?.trim() ?? '';
    if (oldLocation.isNotEmpty) return oldLocation;

    return 'Điểm đến';
  }

  /// Với task thường: lấy deadline làm mốc nhắc.
  /// Với task có địa điểm: lấy startTime làm mốc lịch.
  DateTime get reminderBaseTime {
    if (isLocationTask && startTime != null) {
      return startTime!;
    }

    return deadline;
  }

  /// Giờ nên xuất phát = giờ bắt đầu - thời gian di chuyển.
  DateTime? get departureTime {
    if (!isLocationTask || startTime == null) return null;

    return startTime!.subtract(
      Duration(minutes: travelMinutes),
    );
  }

  /// Giờ notification cho task có địa điểm.
  /// = giờ xuất phát - số phút nhắc trước giờ xuất phát.
  DateTime? get departureNotificationTime {
    final depart = departureTime;
    if (depart == null) return null;

    return depart.subtract(
      Duration(minutes: departReminderMinutes),
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    String? tag,
    bool? isDone,
    DateTime? createdAt,
    int? reminderMinutes,
    TaskType? type,
    DateTime? startTime,
    DateTime? endTime,
    String? locationName,
    String? locationAddress,
    String? googleMapsUrl,
    String? originName,
    String? destinationName,
    int? travelMinutes,
    int? departReminderMinutes,
    String? syncStatus,
    String? userId,
    bool clearLocation = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      type: type ?? this.type,
      startTime: clearLocation ? null : startTime ?? this.startTime,
      endTime: clearLocation ? null : endTime ?? this.endTime,
      locationName: clearLocation ? null : locationName ?? this.locationName,
      locationAddress:
          clearLocation ? null : locationAddress ?? this.locationAddress,
      googleMapsUrl:
          clearLocation ? null : googleMapsUrl ?? this.googleMapsUrl,
      originName: clearLocation ? null : originName ?? this.originName,
      destinationName:
          clearLocation ? null : destinationName ?? this.destinationName,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      departReminderMinutes:
          departReminderMinutes ?? this.departReminderMinutes,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }
}

// Custom manual TypeAdapters to handle schema migrations safely
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
      id: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      description: fields[2] as String? ?? '',
      deadline: fields[3] as DateTime? ?? DateTime.now(),
      priority: fields[4] as TaskPriority? ?? TaskPriority.medium,
      tag: fields[5] as String? ?? 'Khác',
      isDone: fields[6] as bool? ?? false,
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      reminderMinutes: (fields[8] as num?)?.toInt() ?? 60,
      type: fields[9] as TaskType? ?? TaskType.normal,
      startTime: fields[10] as DateTime?,
      endTime: fields[11] as DateTime?,
      locationName: fields[12] as String?,
      locationAddress: fields[13] as String?,
      googleMapsUrl: fields[14] as String?,
      originName: fields[15] as String?,
      destinationName: fields[16] as String?,
      travelMinutes: (fields[17] as num?)?.toInt() ?? 30,
      departReminderMinutes: (fields[18] as num?)?.toInt() ?? 10,
      syncStatus: fields[19] as String? ?? 'synced',
      userId: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.departReminderMinutes)
      ..writeByte(19)
      ..write(obj.syncStatus)
      ..writeByte(20)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}