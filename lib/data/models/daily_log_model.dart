import 'package:hive/hive.dart';

class DailyLogModel extends HiveObject {
  final String id; // Định dạng YYYY-MM-DD
  final DateTime date;
  final int passengerCountMorningIn;
  final int passengerCountMorningOut;
  final int passengerCountAfternoonIn;
  final int passengerCountAfternoonOut;
  final double capital; // Mức vốn bỏ ra hôm đó
  final double actualFuelCost; // Số tiền dầu đổ hôm đó
  final double actualRevenue; // Tổng thu thực tế hôm đó (tự nhập)
  final String? syncStatus; // 'synced' | 'syncing' | 'failed'
  final String? userId;

  DailyLogModel({
    required this.id,
    required this.date,
    this.passengerCountMorningIn = 0,
    this.passengerCountMorningOut = 0,
    this.passengerCountAfternoonIn = 0,
    this.passengerCountAfternoonOut = 0,
    this.capital = 0.0,
    this.actualFuelCost = 0.0,
    this.actualRevenue = 0.0,
    this.syncStatus = 'synced',
    this.userId,
  });

  int get totalPassengers =>
      passengerCountMorningIn +
      passengerCountMorningOut +
      passengerCountAfternoonIn +
      passengerCountAfternoonOut;

  double get routeRevenue => totalPassengers * 90000.0;

  DailyLogModel copyWith({
    String? id,
    DateTime? date,
    int? passengerCountMorningIn,
    int? passengerCountMorningOut,
    int? passengerCountAfternoonIn,
    int? passengerCountAfternoonOut,
    double? capital,
    double? actualFuelCost,
    double? actualRevenue,
    String? syncStatus,
    String? userId,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      date: date ?? this.date,
      passengerCountMorningIn: passengerCountMorningIn ?? this.passengerCountMorningIn,
      passengerCountMorningOut: passengerCountMorningOut ?? this.passengerCountMorningOut,
      passengerCountAfternoonIn: passengerCountAfternoonIn ?? this.passengerCountAfternoonIn,
      passengerCountAfternoonOut: passengerCountAfternoonOut ?? this.passengerCountAfternoonOut,
      capital: capital ?? this.capital,
      actualFuelCost: actualFuelCost ?? this.actualFuelCost,
      actualRevenue: actualRevenue ?? this.actualRevenue,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'passengerCountMorningIn': passengerCountMorningIn,
      'passengerCountMorningOut': passengerCountMorningOut,
      'passengerCountAfternoonIn': passengerCountAfternoonIn,
      'passengerCountAfternoonOut': passengerCountAfternoonOut,
      'capital': capital,
      'actualFuelCost': actualFuelCost,
      'actualRevenue': actualRevenue,
      'userId': userId,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      id: map['id'] as String? ?? '',
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      passengerCountMorningIn: map['passengerCountMorningIn'] as int? ?? 0,
      passengerCountMorningOut: map['passengerCountMorningOut'] as int? ?? 0,
      passengerCountAfternoonIn: map['passengerCountAfternoonIn'] as int? ?? 0,
      passengerCountAfternoonOut: map['passengerCountAfternoonOut'] as int? ?? 0,
      capital: (map['capital'] as num?)?.toDouble() ?? 0.0,
      actualFuelCost: (map['actualFuelCost'] as num?)?.toDouble() ?? 0.0,
      actualRevenue: (map['actualRevenue'] as num?)?.toDouble() ?? 0.0,
      syncStatus: 'synced',
      userId: map['userId'] as String?,
    );
  }
}

class DailyLogModelAdapter extends TypeAdapter<DailyLogModel> {
  @override
  final int typeId = 7;

  @override
  DailyLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLogModel(
      id: fields[0] as String? ?? '',
      date: fields[1] as DateTime? ?? DateTime.now(),
      passengerCountMorningIn: fields[2] as int? ?? 0,
      passengerCountMorningOut: fields[3] as int? ?? 0,
      passengerCountAfternoonIn: fields[4] as int? ?? 0,
      passengerCountAfternoonOut: fields[5] as int? ?? 0,
      capital: (fields[6] as num?)?.toDouble() ?? 0.0,
      actualFuelCost: (fields[7] as num?)?.toDouble() ?? 0.0,
      actualRevenue: (fields[10] as num?)?.toDouble() ?? 0.0,
      syncStatus: fields[8] as String? ?? 'synced',
      userId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.date)
      ..writeByte(2)..write(obj.passengerCountMorningIn)
      ..writeByte(3)..write(obj.passengerCountMorningOut)
      ..writeByte(4)..write(obj.passengerCountAfternoonIn)
      ..writeByte(5)..write(obj.passengerCountAfternoonOut)
      ..writeByte(6)..write(obj.capital)
      ..writeByte(7)..write(obj.actualFuelCost)
      ..writeByte(8)..write(obj.syncStatus)
      ..writeByte(9)..write(obj.userId)
      ..writeByte(10)..write(obj.actualRevenue);
  }
}
