import 'package:hive/hive.dart';
import 'package:taskai/data/models/timetable_slot.dart';

class TimetableRepository {
  final Box<TimetableSlot> _box;

  TimetableRepository(this._box);

  List<TimetableSlot> getAll() {
    final slots = _box.values.toList();

    slots.sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      return a.startPeriod.compareTo(b.startPeriod);
    });

    return slots;
  }

  Future<void> upsert(TimetableSlot slot) async {
    await _box.put(slot.id, slot);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  TimetableSlot? getById(String id) {
    return _box.get(id);
  }
}
