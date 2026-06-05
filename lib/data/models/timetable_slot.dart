import 'package:hive/hive.dart';

class TimetableSlot extends HiveObject {
  final String id;
  final String subjectName;
  final String room;
  final int dayOfWeek; // 1 = Thứ 2, 7 = Chủ Nhật
  final int startPeriod; // 1 to 15
  final int endPeriod; // 1 to 15
  final DateTime startDate;
  final DateTime endDate;
  final String? userId;
  final String? syncStatus; // 'synced', 'syncing', 'failed'

  TimetableSlot({
    required this.id,
    required this.subjectName,
    required this.room,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    required this.startDate,
    required this.endDate,
    this.userId,
    this.syncStatus = 'synced',
  });

  static final Map<int, String> periodStartTimes = {
    1: '07:00',
    2: '07:50',
    3: '08:40',
    4: '09:35',
    5: '10:25',
    6: '11:15',
    7: '12:35',
    8: '13:25',
    9: '14:15',
    10: '15:10',
    11: '16:00',
    12: '16:50',
    13: '17:45',
    14: '18:35',
    15: '19:25',
  };

  static final Map<int, String> periodEndTimes = {
    1: '07:45',
    2: '08:35',
    3: '09:25',
    4: '10:20',
    5: '11:10',
    6: '12:00',
    7: '13:20',
    8: '14:10',
    9: '15:00',
    10: '15:55',
    11: '16:45',
    12: '17:35',
    13: '18:30',
    14: '19:20',
    15: '20:10',
  };

  String get startTimeLabel => periodStartTimes[startPeriod] ?? '07:00';
  String get endTimeLabel => periodEndTimes[endPeriod] ?? '07:45';

  TimetableSlot copyWith({
    String? id,
    String? subjectName,
    String? room,
    int? dayOfWeek,
    int? startPeriod,
    int? endPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? syncStatus,
  }) {
    return TimetableSlot(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startPeriod': startPeriod,
      'endPeriod': endPeriod,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      id: map['id'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      room: map['room'] as String? ?? '',
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startPeriod: (map['startPeriod'] as num?)?.toInt() ?? 1,
      endPeriod: (map['endPeriod'] as num?)?.toInt() ?? 1,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now().add(const Duration(days: 90)),
      userId: map['userId'] as String?,
      syncStatus: 'synced',
    );
  }
}

class TimetableSlotAdapter extends TypeAdapter<TimetableSlot> {
  @override
  final int typeId = 3; // TypeId 3 for TimetableSlot

  @override
  TimetableSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableSlot(
      id: fields[0] as String? ?? '',
      subjectName: fields[1] as String? ?? '',
      room: fields[4] as String? ?? '',
      dayOfWeek: (fields[6] as num?)?.toInt() ?? 1,
      startPeriod: (fields[7] as num?)?.toInt() ?? 1,
      endPeriod: (fields[8] as num?)?.toInt() ?? 1,
      startDate: fields[11] != null
          ? (fields[11] as DateTime)
          : DateTime.now(),
      endDate: fields[12] != null
          ? (fields[12] as DateTime)
          : DateTime.now().add(const Duration(days: 90)),
      userId: fields[9] as String?,
      syncStatus: fields[10] as String? ?? 'synced',
    );
  }

  @override
  void write(BinaryWriter writer, TimetableSlot obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(4)
      ..write(obj.room)
      ..writeByte(6)
      ..write(obj.dayOfWeek)
      ..writeByte(7)
      ..write(obj.startPeriod)
      ..writeByte(8)
      ..write(obj.endPeriod)
      ..writeByte(11)
      ..write(obj.startDate)
      ..writeByte(12)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
