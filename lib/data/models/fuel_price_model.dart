import 'package:hive/hive.dart';

class FuelPriceModel extends HiveObject {
  final double ron95;
  final double e5Ron92;
  final double diesel;
  final String unit;
  final String source;
  final DateTime updatedAt;

  FuelPriceModel({
    required this.ron95,
    required this.e5Ron92,
    required this.diesel,
    required this.unit,
    required this.source,
    required this.updatedAt,
  });

  FuelPriceModel copyWith({
    double? ron95,
    double? e5Ron92,
    double? diesel,
    String? unit,
    String? source,
    DateTime? updatedAt,
  }) {
    return FuelPriceModel(
      ron95: ron95 ?? this.ron95,
      e5Ron92: e5Ron92 ?? this.e5Ron92,
      diesel: diesel ?? this.diesel,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ron95': ron95,
      'e5Ron92': e5Ron92,
      'diesel': diesel,
      'unit': unit,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FuelPriceModel.fromMap(Map<String, dynamic> map) {
    return FuelPriceModel(
      ron95: (map['ron95'] as num?)?.toDouble() ?? 0.0,
      e5Ron92: (map['e5Ron92'] as num?)?.toDouble() ?? 0.0,
      diesel: (map['diesel'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'VND',
      source: map['source'] as String? ?? 'Petrolimex',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}

class FuelPriceModelAdapter extends TypeAdapter<FuelPriceModel> {
  @override
  final int typeId = 5;

  @override
  FuelPriceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelPriceModel(
      ron95: (fields[0] as num?)?.toDouble() ?? 0.0,
      e5Ron92: (fields[1] as num?)?.toDouble() ?? 0.0,
      diesel: (fields[2] as num?)?.toDouble() ?? 0.0,
      unit: fields[3] as String? ?? 'VND',
      source: fields[4] as String? ?? 'Petrolimex',
      updatedAt: fields[5] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, FuelPriceModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.ron95)
      ..writeByte(1)..write(obj.e5Ron92)
      ..writeByte(2)..write(obj.diesel)
      ..writeByte(3)..write(obj.unit)
      ..writeByte(4)..write(obj.source)
      ..writeByte(5)..write(obj.updatedAt);
  }
}
