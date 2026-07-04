import 'package:hive/hive.dart';

class CarModel extends HiveObject {
  final String id;
  final String name;
  final String plateNumber;
  final String carType; // '7_seater' | '16_seater'
  final String fuelType; // 'ron95' | 'e5_ron92' | 'diesel'
  final double fuelConsumptionPer100Km;
  final String status; // 'free' | 'busy' | 'maintenance'
  final String? syncStatus; // 'synced' | 'syncing' | 'failed'
  final String? userId;

  CarModel({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.carType,
    required this.fuelType,
    required this.fuelConsumptionPer100Km,
    required this.status,
    this.syncStatus = 'synced',
    this.userId,
  });

  CarModel copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? carType,
    String? fuelType,
    double? fuelConsumptionPer100Km,
    String? status,
    String? syncStatus,
    String? userId,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      carType: carType ?? this.carType,
      fuelType: fuelType ?? this.fuelType,
      fuelConsumptionPer100Km: fuelConsumptionPer100Km ?? this.fuelConsumptionPer100Km,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'carType': carType,
      'fuelType': fuelType,
      'fuelConsumptionPer100Km': fuelConsumptionPer100Km,
      'status': status,
      'userId': userId,
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      plateNumber: map['plateNumber'] as String? ?? '',
      carType: map['carType'] as String? ?? '7_seater',
      fuelType: map['fuelType'] as String? ?? 'ron95',
      fuelConsumptionPer100Km: (map['fuelConsumptionPer100Km'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'free',
      syncStatus: 'synced',
      userId: map['userId'] as String?,
    );
  }
}

class CarModelAdapter extends TypeAdapter<CarModel> {
  @override
  final int typeId = 4;

  @override
  CarModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CarModel(
      id: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      plateNumber: fields[2] as String? ?? '',
      carType: fields[3] as String? ?? '7_seater',
      fuelType: fields[4] as String? ?? 'ron95',
      fuelConsumptionPer100Km: (fields[5] as num?)?.toDouble() ?? 0.0,
      status: fields[6] as String? ?? 'free',
      syncStatus: fields[7] as String? ?? 'synced',
      userId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CarModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.plateNumber)
      ..writeByte(3)..write(obj.carType)
      ..writeByte(4)..write(obj.fuelType)
      ..writeByte(5)..write(obj.fuelConsumptionPer100Km)
      ..writeByte(6)..write(obj.status)
      ..writeByte(7)..write(obj.syncStatus)
      ..writeByte(8)..write(obj.userId);
  }
}
