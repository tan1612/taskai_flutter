import 'package:hive/hive.dart';
import 'package:taskai/data/models/car_model.dart';

class CarRepository {
  final Box<CarModel> _box;

  CarRepository(this._box);

  List<CarModel> getAll() {
    return _box.values.toList();
  }

  Future<void> upsert(CarModel car) async {
    await _box.put(car.id, car);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  CarModel? getById(String id) {
    return _box.get(id);
  }
}
