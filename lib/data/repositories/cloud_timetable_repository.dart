import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskai/data/models/timetable_slot.dart';

class CloudTimetableRepository {
  final FirebaseFirestore firestore;

  CloudTimetableRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> _collection(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) {
      return firestore.collection('users').doc(userId.trim()).collection('timetable');
    }
    return firestore.collection('timetable');
  }

  Future<void> upsert(TimetableSlot slot, {String? userId}) async {
    final effectiveUid = userId ?? slot.userId;
    await _collection(effectiveUid).doc(slot.id).set(
          _toMap(slot, effectiveUid),
          SetOptions(merge: true),
        );
  }

  Future<void> delete(String slotId, {String? userId}) async {
    await _collection(userId).doc(slotId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> slotStream({String? userId}) {
    return _collection(userId).snapshots();
  }

  TimetableSlot fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return fromMap(map);
  }

  TimetableSlot fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      id: map['id']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startPeriod: (map['startPeriod'] as num?)?.toInt() ?? 1,
      endPeriod: (map['endPeriod'] as num?)?.toInt() ?? 1,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now().add(const Duration(days: 90)),
      userId: map['userId']?.toString(),
      syncStatus: 'synced',
    );
  }

  Map<String, dynamic> _toMap(TimetableSlot slot, String? effectiveUid) {
    return {
      'id': slot.id,
      'subjectName': slot.subjectName,
      'room': slot.room,
      'dayOfWeek': slot.dayOfWeek,
      'startPeriod': slot.startPeriod,
      'endPeriod': slot.endPeriod,
      'startDate': slot.startDate.toIso8601String(),
      'endDate': slot.endDate.toIso8601String(),
      'userId': effectiveUid,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
