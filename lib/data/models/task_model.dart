import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  high,

  @HiveField(1)
  medium,

  @HiveField(2)
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

@HiveType(typeId: 2)
enum TaskType {
  @HiveField(0)
  normal,

  @HiveField(1)
  location,
}

extension TaskTypeX on TaskType {
  String get label {
    switch (this) {
      case TaskType.normal:
        return 'Thông thường';
      case TaskType.location:
        return 'Có địa điểm';
    }
  }
}

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  /// Task thường: deadline.
  /// Task có địa điểm: giữ để tương thích, thường bằng endTime.
  @HiveField(3)
  final DateTime deadline;

  @HiveField(4)
  final TaskPriority priority;

  @HiveField(5)
  final String tag;

  @HiveField(6)
  final bool isDone;

  @HiveField(7)
  final DateTime createdAt;

  /// Task thường:
  /// 0 = không nhắc
  /// -1 = demo sau 10 giây
  /// 5, 10, 15, 30, 60, 1440 = nhắc trước deadline
  ///
  /// Task có địa điểm:
  /// vẫn giữ field này để tương thích UI cũ.
  @HiveField(8)
  final int reminderMinutes;

  @HiveField(9)
  final TaskType type;

  /// Task có địa điểm: giờ bắt đầu lịch.
  @HiveField(10)
  final DateTime? startTime;

  /// Task có địa điểm: giờ kết thúc lịch.
  @HiveField(11)
  final DateTime? endTime;

  /// Tên địa điểm cũ, giữ để tương thích.
  /// Có thể hiểu là điểm đến.
  @HiveField(12)
  final String? locationName;

  /// Địa chỉ/ghi chú địa điểm cũ, giữ để tương thích.
  @HiveField(13)
  final String? locationAddress;

  /// Link Google Maps nếu có.
  @HiveField(14)
  final String? googleMapsUrl;

  /// Điểm đi, ví dụ: Nhà, KTX, Công ty.
  @HiveField(15)
  final String? originName;

  /// Điểm đến, ví dụ: Trường, Công ty, Quán cafe.
  @HiveField(16)
  final String? destinationName;

  /// Thời gian di chuyển dự kiến, đơn vị phút.
  /// Ví dụ: 15, 30, 45, 60.
  @HiveField(17)
  final int travelMinutes;

  /// Nhắc trước giờ xuất phát, đơn vị phút.
  /// Ví dụ:
  /// - Nếu startTime 07:00
  /// - travelMinutes 30
  /// - departReminderMinutes 10
  /// => giờ xuất phát 06:30
  /// => thông báo lúc 06:20
  @HiveField(18)
  final int departReminderMinutes;

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
    );
  }
}