import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/repositories/trip_repository.dart';
import 'package:taskai/data/repositories/cloud_trip_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/providers/car_provider.dart';

final _cloudTripRepositoryProvider = Provider<CloudTripRepository>((ref) {
  return CloudTripRepository(FirebaseFirestore.instance);
});

class TripNotifier extends StateNotifier<List<TripModel>> {
  final TripRepository repository;
  final Ref ref;
  StreamSubscription? _syncSubscription;

  TripNotifier(this.repository, this.ref) : super(repository.getAll()) {
    _initSync();
  }

  void _initSync() {
    ref.listen<User?>(authStateProvider.select((v) => v.value), (prev, next) {
      _subscribeToUserTrips(next);
    }, fireImmediately: true);
  }

  void _subscribeToUserTrips(User? user) {
    _syncSubscription?.cancel();

    final userId = user?.uid;
    final stream = ref.read(_cloudTripRepositoryProvider).tripStream(userId: userId);

    _syncSubscription = stream.listen((snapshot) {
      _handleCloudSnapshot(snapshot, userId);
    }, onError: (e) {
      print('Lỗi đồng bộ chuyến xe realtime: $e');
    });
  }

  Future<void> _handleCloudSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String? userId,
  ) async {
    final cloudTrips = snapshot.docs
        .map((doc) => ref.read(_cloudTripRepositoryProvider).fromDoc(doc))
        .toList();
    final cloudIds = cloudTrips.map((t) => t.id).toSet();

    final localTrips = repository.getAll();

    for (final cloudTrip in cloudTrips) {
      final local = repository.getById(cloudTrip.id);

      if (local == null) {
        final updatedTrip = cloudTrip.copyWith(syncStatus: 'synced', userId: userId);
        await repository.upsert(updatedTrip);
        await _scheduleNotificationIfEnabled(updatedTrip);
      } else {
        if (!_areTripsEqual(local, cloudTrip) || local.syncStatus != 'synced') {
          if (local.syncStatus == 'syncing') {
            continue;
          }
          final updatedTrip = cloudTrip.copyWith(syncStatus: 'synced', userId: userId);
          await repository.upsert(updatedTrip);
          await _scheduleNotificationIfEnabled(updatedTrip);
        }
      }
    }

    // Check for deletions
    for (final local in localTrips) {
      if (userId != null && local.userId != userId) {
        continue;
      }
      if (local.syncStatus == 'synced' && !cloudIds.contains(local.id)) {
        await repository.delete(local.id);
        try {
          await ref.read(notificationServiceProvider).cancelTripReminder(local.id);
        } catch (e) {
          print('Lỗi hủy notification chuyến: $e');
        }
      }
    }

    state = repository.getAll();
    _syncCarStatuses();
  }

  bool _areTripsEqual(TripModel a, TripModel b) {
    return a.customerName == b.customerName &&
        a.customerPhone == b.customerPhone &&
        a.carId == b.carId &&
        a.carType == b.carType &&
        a.fuelType == b.fuelType &&
        a.startTime.isAtSameMomentAs(b.startTime) &&
        a.pickupLocation == b.pickupLocation &&
        a.destination == b.destination &&
        a.estimatedKm == b.estimatedKm &&
        a.fuelConsumptionPer100Km == b.fuelConsumptionPer100Km &&
        a.fuelPrice == b.fuelPrice &&
        a.fuelCost == b.fuelCost &&
        a.tollFee == b.tollFee &&
        a.driverFee == b.driverFee &&
        a.otherFee == b.otherFee &&
        a.expectedProfit == b.expectedProfit &&
        a.suggestedPrice == b.suggestedPrice &&
        a.finalPrice == b.finalPrice &&
        a.deposit == b.deposit &&
        a.remainingAmount == b.remainingAmount &&
        a.status == b.status &&
        a.note == b.note;
  }

  Future<void> addOrUpdate(TripModel trip) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    final localTrip = trip.copyWith(syncStatus: 'syncing', userId: userId);

    await repository.upsert(localTrip);
    state = repository.getAll();

    await _scheduleNotificationIfEnabled(localTrip);
    _syncTripToCloud(localTrip);
    _updateCarStatusForTrip(localTrip);
  }

  Future<void> deleteTrip(String id) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;

    final trip = repository.getById(id);
    await repository.delete(id);
    state = repository.getAll();

    try {
      await ref.read(notificationServiceProvider).cancelTripReminder(id);
    } catch (e) {
      print('Lỗi hủy notification: $e');
    }

    try {
      await ref.read(_cloudTripRepositoryProvider).delete(id, userId: userId);
    } catch (e) {
      print('Lỗi delete cloud: $e');
    }

    if (trip != null) {
      _syncCarStatuses();
    }
  }

  Future<void> _syncTripToCloud(TripModel trip) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    try {
      await ref.read(_cloudTripRepositoryProvider).upsert(trip, userId: userId);
      final synced = trip.copyWith(syncStatus: 'synced');
      await repository.upsert(synced);
      state = repository.getAll();
    } catch (e) {
      print('Lỗi upload chuyến lên cloud: $e');
      final failed = trip.copyWith(syncStatus: 'failed');
      await repository.upsert(failed);
      state = repository.getAll();
    }
  }

  Future<void> _scheduleNotificationIfEnabled(TripModel trip) async {
    final enabled = ref.read(notificationEnabledProvider);
    if (!enabled) return;

    try {
      await ref.read(notificationServiceProvider).scheduleTripReminder(trip);
    } catch (e) {
      print('Lỗi đặt lịch thông báo chuyến: $e');
    }
  }

  // Tự động đồng bộ cập nhật trạng thái xe khi chuyến xe thay đổi
  void _updateCarStatusForTrip(TripModel trip) {
    try {
      final cars = ref.read(carProvider);
      final car = cars.firstWhere((c) => c.id == trip.carId, orElse: () => throw Exception('Không tìm thấy xe'));
      if (car.status == 'maintenance') return; // Giữ bảo trì nếu xe đang bảo trì

      String newStatus = 'free';
      if (trip.status == 'confirmed' || trip.status == 'running') {
        newStatus = 'busy';
      } else if (trip.status == 'completed' || trip.status == 'cancelled') {
        final hasOtherActive = state.any((t) =>
            t.id != trip.id &&
            t.carId == trip.carId &&
            (t.status == 'confirmed' || t.status == 'running'));
        newStatus = hasOtherActive ? 'busy' : 'free';
      }

      if (car.status != newStatus) {
        final updatedCar = car.copyWith(status: newStatus);
        ref.read(carProvider.notifier).updateCar(updatedCar);
      }
    } catch (e) {
      print('Lỗi cập nhật trạng thái xe: $e');
    }
  }

  // Đồng bộ lại tất cả trạng thái xe dựa trên tất cả chuyến xe hiện có
  void _syncCarStatuses() {
    try {
      final cars = ref.read(carProvider);
      for (final car in cars) {
        if (car.status == 'maintenance') continue;

        final hasActiveTrip = state.any((t) =>
            t.carId == car.id &&
            (t.status == 'confirmed' || t.status == 'running'));

        final targetStatus = hasActiveTrip ? 'busy' : 'free';
        if (car.status != targetStatus) {
          final updatedCar = car.copyWith(status: targetStatus);
          ref.read(carProvider.notifier).updateCar(updatedCar);
        }
      }
    } catch (e) {
      print('Lỗi đồng bộ lại trạng thái xe: $e');
    }
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, List<TripModel>>((ref) {
  final repo = ref.read(tripRepositoryProvider);
  return TripNotifier(repo, ref);
});
