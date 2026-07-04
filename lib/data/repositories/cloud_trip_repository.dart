import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskai/data/models/trip_model.dart';

class CloudTripRepository {
  final FirebaseFirestore firestore;

  CloudTripRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> _collection(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) {
      return firestore.collection('users').doc(userId.trim()).collection('trips');
    }
    return firestore.collection('trips');
  }

  Future<void> upsert(TripModel trip, {String? userId}) async {
    final effectiveUid = userId ?? trip.userId;
    await _collection(effectiveUid).doc(trip.id).set(
          _toMap(trip, effectiveUid),
          SetOptions(merge: true),
        );
  }

  Future<void> delete(String tripId, {String? userId}) async {
    await _collection(userId).doc(tripId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tripStream({String? userId}) {
    return _collection(userId).snapshots();
  }

  TripModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return fromMap(map);
  }

  TripModel fromMap(Map<String, dynamic> map) {
    DateTime parseTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    return TripModel(
      id: map['id']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      carId: map['carId']?.toString() ?? '',
      carType: map['carType']?.toString() ?? '7_seater',
      fuelType: map['fuelType']?.toString() ?? 'ron95',
      startTime: parseTime(map['startTime'], DateTime.now()),
      pickupLocation: map['pickupLocation']?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
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
      status: map['status']?.toString() ?? 'pending',
      note: map['note']?.toString() ?? '',
      createdAt: parseTime(map['createdAt'], DateTime.now()),
      updatedAt: parseTime(map['updatedAt'], DateTime.now()),
      syncStatus: 'synced',
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(TripModel trip, String? effectiveUid) {
    return {
      'id': trip.id,
      'customerName': trip.customerName,
      'customerPhone': trip.customerPhone,
      'carId': trip.carId,
      'carType': trip.carType,
      'fuelType': trip.fuelType,
      'startTime': Timestamp.fromDate(trip.startTime),
      'pickupLocation': trip.pickupLocation,
      'destination': trip.destination,
      'estimatedKm': trip.estimatedKm,
      'fuelConsumptionPer100Km': trip.fuelConsumptionPer100Km,
      'fuelPrice': trip.fuelPrice,
      'fuelCost': trip.fuelCost,
      'tollFee': trip.tollFee,
      'driverFee': trip.driverFee,
      'otherFee': trip.otherFee,
      'expectedProfit': trip.expectedProfit,
      'suggestedPrice': trip.suggestedPrice,
      'finalPrice': trip.finalPrice,
      'deposit': trip.deposit,
      'remainingAmount': trip.remainingAmount,
      'status': trip.status,
      'note': trip.note,
      'createdAt': Timestamp.fromDate(trip.createdAt),
      'updatedAt': Timestamp.fromDate(trip.updatedAt),
      'userId': effectiveUid,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
