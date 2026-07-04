import 'package:hive/hive.dart';
import 'package:taskai/data/models/trip_model.dart';

class TripRepository {
  final Box<TripModel> _box;

  TripRepository(this._box);

  List<TripModel> getAll() {
    final trips = _box.values.toList();

    // Sắp xếp các chuyến đi theo thứ tự ngày giờ đi (startTime) tăng dần
    trips.sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });

    return trips;
  }

  Future<void> upsert(TripModel trip) async {
    await _box.put(trip.id, trip);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  TripModel? getById(String id) {
    return _box.get(id);
  }
}
