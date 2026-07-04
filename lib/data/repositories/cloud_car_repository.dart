import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskai/data/models/car_model.dart';

class CloudCarRepository {
  final FirebaseFirestore firestore;

  CloudCarRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> _collection(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) {
      return firestore.collection('users').doc(userId.trim()).collection('cars');
    }
    return firestore.collection('cars');
  }

  Future<void> upsert(CarModel car, {String? userId}) async {
    final effectiveUid = userId ?? car.userId;
    await _collection(effectiveUid).doc(car.id).set(
          _toMap(car, effectiveUid),
          SetOptions(merge: true),
        );
  }

  Future<void> delete(String carId, {String? userId}) async {
    await _collection(userId).doc(carId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> carStream({String? userId}) {
    return _collection(userId).snapshots();
  }

  CarModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return fromMap(map);
  }

  CarModel fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      plateNumber: map['plateNumber']?.toString() ?? '',
      carType: map['carType']?.toString() ?? '7_seater',
      fuelType: map['fuelType']?.toString() ?? 'ron95',
      fuelConsumptionPer100Km: (map['fuelConsumptionPer100Km'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'free',
      syncStatus: 'synced',
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(CarModel car, String? effectiveUid) {
    return {
      'id': car.id,
      'name': car.name,
      'plateNumber': car.plateNumber,
      'carType': car.carType,
      'fuelType': car.fuelType,
      'fuelConsumptionPer100Km': car.fuelConsumptionPer100Km,
      'status': car.status,
      'userId': effectiveUid,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
