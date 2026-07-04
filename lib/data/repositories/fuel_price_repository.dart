import 'package:hive/hive.dart';
import 'package:taskai/data/models/fuel_price_model.dart';

class FuelPriceRepository {
  final Box<FuelPriceModel> _box;

  FuelPriceRepository(this._box);

  FuelPriceModel getPrices() {
    // Trả về giá hiện tại, nếu chưa có thì trả về giá mặc định của Petrolimex
    return _box.get('current') ?? FuelPriceModel(
      ron95: 23210.0,
      e5Ron92: 22080.0,
      diesel: 19750.0,
      unit: 'VND',
      source: 'Petrolimex',
      updatedAt: DateTime.now(),
    );
  }

  Future<void> savePrices(FuelPriceModel prices) async {
    await _box.put('current', prices);
  }
}
