import 'package:hive/hive.dart';

class TripModel extends HiveObject {
  final String id;
  final String customerName;
  final String customerPhone;
  final String carId;
  final String carType; // '7_seater' | '16_seater'
  final String fuelType; // 'ron95' | 'e5_ron92' | 'diesel'
  final DateTime startTime; // Ngày giờ đi
  final String pickupLocation;
  final String destination;
  final double estimatedKm;
  final double fuelConsumptionPer100Km;
  final double fuelPrice;
  final double fuelCost;
  final double tollFee;
  final double driverFee;
  final double otherFee;
  final double expectedProfit;
  final double suggestedPrice;
  final double finalPrice;
  final double deposit;
  final double remainingAmount;
  final String status; // 'pending' | 'confirmed' | 'running' | 'completed' | 'cancelled'
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // 'synced' | 'syncing' | 'failed'
  final String? userId;

  TripModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.carId,
    required this.carType,
    required this.fuelType,
    required this.startTime,
    required this.pickupLocation,
    required this.destination,
    required this.estimatedKm,
    required this.fuelConsumptionPer100Km,
    required this.fuelPrice,
    required this.fuelCost,
    required this.tollFee,
    required this.driverFee,
    required this.otherFee,
    required this.expectedProfit,
    required this.suggestedPrice,
    required this.finalPrice,
    required this.deposit,
    required this.remainingAmount,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
    this.userId,
  });

  TripModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? carId,
    String? carType,
    String? fuelType,
    DateTime? startTime,
    String? pickupLocation,
    String? destination,
    double? estimatedKm,
    double? fuelConsumptionPer100Km,
    double? fuelPrice,
    double? fuelCost,
    double? tollFee,
    double? driverFee,
    double? otherFee,
    double? expectedProfit,
    double? suggestedPrice,
    double? finalPrice,
    double? deposit,
    double? remainingAmount,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
  }) {
    return TripModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      carId: carId ?? this.carId,
      carType: carType ?? this.carType,
      fuelType: fuelType ?? this.fuelType,
      startTime: startTime ?? this.startTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      estimatedKm: estimatedKm ?? this.estimatedKm,
      fuelConsumptionPer100Km: fuelConsumptionPer100Km ?? this.fuelConsumptionPer100Km,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      fuelCost: fuelCost ?? this.fuelCost,
      tollFee: tollFee ?? this.tollFee,
      driverFee: driverFee ?? this.driverFee,
      otherFee: otherFee ?? this.otherFee,
      expectedProfit: expectedProfit ?? this.expectedProfit,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      deposit: deposit ?? this.deposit,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'carId': carId,
      'carType': carType,
      'fuelType': fuelType,
      'startTime': startTime.toIso8601String(),
      'pickupLocation': pickupLocation,
      'destination': destination,
      'estimatedKm': estimatedKm,
      'fuelConsumptionPer100Km': fuelConsumptionPer100Km,
      'fuelPrice': fuelPrice,
      'fuelCost': fuelCost,
      'tollFee': tollFee,
      'driverFee': driverFee,
      'otherFee': otherFee,
      'expectedProfit': expectedProfit,
      'suggestedPrice': suggestedPrice,
      'finalPrice': finalPrice,
      'deposit': deposit,
      'remainingAmount': remainingAmount,
      'status': status,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      carType: map['carType'] as String? ?? '7_seater',
      fuelType: map['fuelType'] as String? ?? 'ron95',
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : DateTime.now(),
      pickupLocation: map['pickupLocation'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      estimatedKm: (map['estimatedKm'] as num?)?.toDouble() ?? 0.0,
      fuelConsumptionPer100Km: (map['fuelConsumptionPer100Km'] as num?)?.toDouble() ?? 0.0,
      fuelPrice: (map['fuelPrice'] as num?)?.toDouble() ?? 0.0,
      fuelCost: (map['fuelCost'] as num?)?.toDouble() ?? 0.0,
      tollFee: (map['tollFee'] as num?)?.toDouble() ?? 0.0,
      driverFee: (map['driverFee'] as num?)?.toDouble() ?? 0.0,
      otherFee: (map['otherFee'] as num?)?.toDouble() ?? 0.0,
      expectedProfit: (map['expectedProfit'] as num?)?.toDouble() ?? 0.0,
      suggestedPrice: (map['suggestedPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (map['finalPrice'] as num?)?.toDouble() ?? 0.0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String? ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      syncStatus: 'synced',
      userId: map['userId'] as String?,
    );
  }
}

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 6;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel(
      id: fields[0] as String? ?? '',
      customerName: fields[1] as String? ?? '',
      customerPhone: fields[2] as String? ?? '',
      carId: fields[3] as String? ?? '',
      carType: fields[4] as String? ?? '7_seater',
      fuelType: fields[5] as String? ?? 'ron95',
      startTime: fields[6] as DateTime? ?? DateTime.now(),
      pickupLocation: fields[7] as String? ?? '',
      destination: fields[8] as String? ?? '',
      estimatedKm: (fields[9] as num?)?.toDouble() ?? 0.0,
      fuelConsumptionPer100Km: (fields[10] as num?)?.toDouble() ?? 0.0,
      fuelPrice: (fields[11] as num?)?.toDouble() ?? 0.0,
      fuelCost: (fields[12] as num?)?.toDouble() ?? 0.0,
      tollFee: (fields[13] as num?)?.toDouble() ?? 0.0,
      driverFee: (fields[14] as num?)?.toDouble() ?? 0.0,
      otherFee: (fields[15] as num?)?.toDouble() ?? 0.0,
      expectedProfit: (fields[16] as num?)?.toDouble() ?? 0.0,
      suggestedPrice: (fields[17] as num?)?.toDouble() ?? 0.0,
      finalPrice: (fields[18] as num?)?.toDouble() ?? 0.0,
      deposit: (fields[19] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (fields[20] as num?)?.toDouble() ?? 0.0,
      status: fields[21] as String? ?? 'pending',
      note: fields[22] as String? ?? '',
      createdAt: fields[23] as DateTime? ?? DateTime.now(),
      updatedAt: fields[24] as DateTime? ?? DateTime.now(),
      syncStatus: fields[25] as String? ?? 'synced',
      userId: fields[26] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.customerName)
      ..writeByte(2)..write(obj.customerPhone)
      ..writeByte(3)..write(obj.carId)
      ..writeByte(4)..write(obj.carType)
      ..writeByte(5)..write(obj.fuelType)
      ..writeByte(6)..write(obj.startTime)
      ..writeByte(7)..write(obj.pickupLocation)
      ..writeByte(8)..write(obj.destination)
      ..writeByte(9)..write(obj.estimatedKm)
      ..writeByte(10)..write(obj.fuelConsumptionPer100Km)
      ..writeByte(11)..write(obj.fuelPrice)
      ..writeByte(12)..write(obj.fuelCost)
      ..writeByte(13)..write(obj.tollFee)
      ..writeByte(14)..write(obj.driverFee)
      ..writeByte(15)..write(obj.otherFee)
      ..writeByte(16)..write(obj.expectedProfit)
      ..writeByte(17)..write(obj.suggestedPrice)
      ..writeByte(18)..write(obj.finalPrice)
      ..writeByte(19)..write(obj.deposit)
      ..writeByte(20)..write(obj.remainingAmount)
      ..writeByte(21)..write(obj.status)
      ..writeByte(22)..write(obj.note)
      ..writeByte(23)..write(obj.createdAt)
      ..writeByte(24)..write(obj.updatedAt)
      ..writeByte(25)..write(obj.syncStatus)
      ..writeByte(26)..write(obj.userId);
  }
}
