import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/timetable_slot.dart';
import 'package:taskai/data/repositories/cloud_timetable_repository.dart';
import 'package:taskai/data/repositories/timetable_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';

final _cloudTimetableRepositoryProvider = Provider<CloudTimetableRepository>((ref) {
  return CloudTimetableRepository(FirebaseFirestore.instance);
});

class TimetableNotifier extends StateNotifier<List<TimetableSlot>> {
  final TimetableRepository repository;
  final Ref ref;
  StreamSubscription? _syncSubscription;

  TimetableNotifier(this.repository, this.ref) : super(repository.getAll()) {
    _initSync();
  }

  void _initSync() {
    ref.listen<User?>(authStateProvider.select((v) => v.value), (prev, next) {
      _subscribeToUserSlots(next);
    }, fireImmediately: true);
  }

  void _subscribeToUserSlots(User? user) {
    _syncSubscription?.cancel();

    final userId = user?.uid;
    final stream = ref.read(_cloudTimetableRepositoryProvider).slotStream(userId: userId);

    _syncSubscription = stream.listen((snapshot) {
      _handleCloudSnapshot(snapshot, userId);
    }, onError: (e) {
      print('Lỗi đồng bộ timetable realtime: $e');
    });
  }

  Future<void> _handleCloudSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String? userId,
  ) async {
    final cloudSlots = snapshot.docs
        .map((doc) => ref.read(_cloudTimetableRepositoryProvider).fromDoc(doc))
        .toList();
    final cloudIds = cloudSlots.map((s) => s.id).toSet();

    final localSlots = repository.getAll();

    for (final cloudSlot in cloudSlots) {
      final local = repository.getById(cloudSlot.id);

      if (local == null) {
        final updatedSlot = cloudSlot.copyWith(syncStatus: 'synced', userId: userId);
        await repository.upsert(updatedSlot);
        await _scheduleNotificationIfEnabled(updatedSlot);
      } else {
        if (!_areSlotsEqual(local, cloudSlot) || local.syncStatus != 'synced') {
          if (local.syncStatus == 'syncing') {
            continue;
          }
          if (local.syncStatus == 'failed') {
            _syncSlotToCloud(local);
          } else {
            final updatedSlot = cloudSlot.copyWith(syncStatus: 'synced', userId: userId);
            await repository.upsert(updatedSlot);
            await _scheduleNotificationIfEnabled(updatedSlot);
          }
        }
      }
    }

    for (final local in localSlots) {
      if (userId != null && local.userId != userId) {
        continue;
      }
      if (local.syncStatus == 'synced' && !cloudIds.contains(local.id)) {
        await repository.delete(local.id);
        try {
          await ref.read(notificationServiceProvider).cancelTimetableSlotReminder(local.id);
        } catch (e) {
          print('Lỗi hủy notification môn học: $e');
        }
      }
    }

    state = repository.getAll();
  }

  bool _areSlotsEqual(TimetableSlot a, TimetableSlot b) {
    return a.subjectName == b.subjectName &&
        a.room == b.room &&
        a.dayOfWeek == b.dayOfWeek &&
        a.startPeriod == b.startPeriod &&
        a.endPeriod == b.endPeriod &&
        a.startDate.isAtSameMomentAs(b.startDate) &&
        a.endDate.isAtSameMomentAs(b.endDate) &&
        a.userId == b.userId;
  }

  Future<void> addOrUpdate(TimetableSlot slot) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    final localSlot = slot.copyWith(syncStatus: 'syncing', userId: userId);

    await repository.upsert(localSlot);
    state = repository.getAll();

    await _scheduleNotificationIfEnabled(localSlot);

    _syncSlotToCloud(localSlot);
  }

  Future<void> delete(String id) async {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.uid;
    final slot = repository.getById(id);
    
    if (slot != null) {
      await repository.delete(id);
      state = repository.getAll();

      try {
        await ref.read(notificationServiceProvider).cancelTimetableSlotReminder(id);
      } catch (e) {
        print('Lỗi hủy notification: $e');
      }

      _deleteSlotFromCloud(id, userId);
    }
  }

  Future<void> _syncSlotToCloud(TimetableSlot slot) async {
    final userId = ref.read(authNotifierProvider).user?.uid;
    try {
      await ref.read(_cloudTimetableRepositoryProvider).upsert(slot, userId: userId);
      final syncedSlot = slot.copyWith(syncStatus: 'synced', userId: userId);
      await repository.upsert(syncedSlot);
      state = repository.getAll();
    } catch (e) {
      print('Không thể sync timetable slot lên Firestore: $e');
      final failedSlot = slot.copyWith(syncStatus: 'failed', userId: userId);
      await repository.upsert(failedSlot);
      state = repository.getAll();
    }
  }

  Future<void> _deleteSlotFromCloud(String id, String? userId) async {
    try {
      await ref.read(_cloudTimetableRepositoryProvider).delete(id, userId: userId);
    } catch (e) {
      print('Không thể xóa slot trên Firestore: $e');
    }
  }

  Future<void> _scheduleNotificationIfEnabled(TimetableSlot slot) async {
    final notificationsEnabled = ref.read(notificationEnabledProvider);
    if (notificationsEnabled) {
      try {
        await ref.read(notificationServiceProvider).cancelTimetableSlotReminder(slot.id);
        await ref.read(notificationServiceProvider).scheduleTimetableSlotReminder(slot);
      } catch (e) {
        print('Lỗi đặt notification môn học: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}

final timetableProvider =
    StateNotifierProvider<TimetableNotifier, List<TimetableSlot>>((ref) {
  return TimetableNotifier(ref.watch(timetableRepositoryProvider), ref);
});
