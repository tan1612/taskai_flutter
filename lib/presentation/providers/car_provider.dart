import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/data/repositories/car_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';

class CarNotifier extends StateNotifier<List<CarModel>> {
  final CarRepository repository;
  final Ref ref;
  StreamSubscription? _syncSubscription;

  CarNotifier(this.repository, this.ref) : super([]) {
    _initDefaultCarsAndSync();
  }

  Future<void> _initDefaultCarsAndSync() async {
    final localCars = repository.getAll();
    if (localCars.isEmpty) {
      final default7 = CarModel(
        id: 'car_7_seater',
        name: 'Toyota Innova',
        plateNumber: '29A-123.45',
        carType: '7_seater',
        fuelType: 'ron95',
        fuelConsumptionPer100Km: 9.0,
        status: 'free',
      );
      final default16 = CarModel(
        id: 'car_16_seater',
        name: 'Ford Transit',
        plateNumber: '29B-678.90',
        carType: '16_seater',
        fuelType: 'diesel',
        fuelConsumptionPer100Km: 11.5,
        status: 'free',
      );
      await repository.upsert(default7);
      await repository.upsert(default16);
    }
    state = repository.getAll();
    _initSync();
  }

  void _initSync() {
    ref.listen<User?>(authStateProvider.select((v) => v.value), (prev, next) {
      _subscribeToUserCars(next);
    }, fireImmediately: true);
  }

  void _subscribeToUserCars(User? user) {
    _syncSubscription?.cancel();
    final userId = user?.uid;
    final stream = ref.read(cloudCarRepositoryProvider).carStream(userId: userId);

    _syncSubscription = stream.listen((snapshot) {
      _handleCloudSnapshot(snapshot, userId);
    }, onError: (e) {
      print('Lỗi đồng bộ xe realtime: $e');
    });
  }

  Future<void> _handleCloudSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String? userId,
  ) async {
    final cloudCars = snapshot.docs
        .map((doc) => ref.read(cloudCarRepositoryProvider).fromDoc(doc))
        .toList();

    for (final cloudCar in cloudCars) {
      final local = repository.getById(cloudCar.id);

      if (local == null) {
        final updatedCar = cloudCar.copyWith(syncStatus: 'synced', userId: userId);
        await repository.upsert(updatedCar);
      } else {
        if (!_areCarsEqual(local, cloudCar) || local.syncStatus != 'synced') {
          if (local.syncStatus == 'syncing') {
            continue;
          }
          final updatedCar = cloudCar.copyWith(syncStatus: 'synced', userId: userId);
          await repository.upsert(updatedCar);
        }
      }
    }

    state = repository.getAll();
  }

  bool _areCarsEqual(CarModel a, CarModel b) {
    return a.name == b.name &&
        a.plateNumber == b.plateNumber &&
        a.carType == b.carType &&
        a.fuelType == b.fuelType &&
        a.fuelConsumptionPer100Km == b.fuelConsumptionPer100Km &&
        a.status == b.status;
  }

  Future<void> updateCar(CarModel car) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    final localCar = car.copyWith(syncStatus: 'syncing', userId: userId);

    await repository.upsert(localCar);
    state = repository.getAll();

    _syncCarToCloud(localCar);
  }

  Future<void> _syncCarToCloud(CarModel car) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    try {
      await ref.read(cloudCarRepositoryProvider).upsert(car, userId: userId);
      final synced = car.copyWith(syncStatus: 'synced');
      await repository.upsert(synced);
      state = repository.getAll();
    } catch (e) {
      print('Lỗi upload xe lên cloud: $e');
      final failed = car.copyWith(syncStatus: 'failed');
      await repository.upsert(failed);
      state = repository.getAll();
    }
  }
}

final carProvider = StateNotifierProvider<CarNotifier, List<CarModel>>((ref) {
  final repo = ref.read(carRepositoryProvider);
  return CarNotifier(repo, ref);
});
