import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/daily_log_model.dart';
import 'package:taskai/data/repositories/daily_log_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';

class DailyLogNotifier extends StateNotifier<List<DailyLogModel>> {
  final DailyLogRepository localRepo;
  final Ref ref;

  DailyLogNotifier({
    required this.localRepo,
    required this.ref,
  }) : super([]) {
    _loadLocalLogs();
    _subscribeToUserLogs();
  }

  void _loadLocalLogs() {
    final logs = localRepo.getAllLogs();
    state = logs..sort((a, b) => b.date.compareTo(a.date)); // Sắp xếp ngày mới nhất lên đầu
  }

  void _subscribeToUserLogs() {
    ref.listen(authNotifierProvider, (previous, next) {
      final user = next.user;
      if (user != null) {
        final cloudRepo = ref.read(cloudDailyLogRepositoryProvider);
        cloudRepo.logStream(userId: user.uid).listen((cloudLogs) {
          _mergeCloudLogs(cloudLogs);
        }, onError: (e) {
          debugPrint('Lỗi lắng nghe đồng bộ log từ Firestore: $e');
        });
      } else {
        _loadLocalLogs(); // Quay lại dữ liệu local nếu đăng xuất
      }
    });
  }

  Future<void> _mergeCloudLogs(List<DailyLogModel> cloudLogs) async {
    for (final cloudLog in cloudLogs) {
      final localLog = localRepo.getLogByDate(cloudLog.id);
      if (localLog == null || _isLogDifferent(localLog, cloudLog)) {
        final mergedLog = cloudLog.copyWith(syncStatus: 'synced');
        await localRepo.saveLogLocally(mergedLog);
      }
    }
    _loadLocalLogs();
  }

  bool _isLogDifferent(DailyLogModel a, DailyLogModel b) {
    return a.passengerCountMorningIn != b.passengerCountMorningIn ||
        a.passengerCountMorningOut != b.passengerCountMorningOut ||
        a.passengerCountAfternoonIn != b.passengerCountAfternoonIn ||
        a.passengerCountAfternoonOut != b.passengerCountAfternoonOut ||
        a.capital != b.capital ||
        a.actualFuelCost != b.actualFuelCost ||
        a.userId != b.userId;
  }

  DailyLogModel? getLogByDate(String dateStr) {
    try {
      return state.firstWhere((log) => log.id == dateStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyLog({
    required String dateStr,
    required int morningIn,
    required int morningOut,
    required int afternoonIn,
    required int afternoonOut,
    required double capital,
    required double actualFuelCost,
  }) async {
    final date = DateTime.parse(dateStr);
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    final newLog = DailyLogModel(
      id: dateStr,
      date: date,
      passengerCountMorningIn: morningIn,
      passengerCountMorningOut: morningOut,
      passengerCountAfternoonIn: afternoonIn,
      passengerCountAfternoonOut: afternoonOut,
      capital: capital,
      actualFuelCost: actualFuelCost,
      syncStatus: user != null ? 'syncing' : 'synced',
      userId: user?.uid,
    );

    // 1. Lưu local trước
    await localRepo.saveLogLocally(newLog);
    _loadLocalLogs();

    // 2. Đồng bộ cloud nếu có tài khoản
    if (user != null) {
      try {
        final cloudRepo = ref.read(cloudDailyLogRepositoryProvider);
        await cloudRepo.saveLogToCloud(userId: user.uid, log: newLog);
        await localRepo.saveLogLocally(newLog.copyWith(syncStatus: 'synced'));
        _loadLocalLogs();
      } catch (e) {
        debugPrint('Lỗi đồng bộ log lên cloud, giữ trạng thái failed để đồng bộ lại: $e');
        await localRepo.saveLogLocally(newLog.copyWith(syncStatus: 'failed'));
        _loadLocalLogs();
      }
    }
  }

  Future<void> deleteDailyLog(String dateStr) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    await localRepo.deleteLogLocally(dateStr);
    _loadLocalLogs();

    if (user != null) {
      try {
        final cloudRepo = ref.read(cloudDailyLogRepositoryProvider);
        await cloudRepo.deleteLogFromCloud(userId: user.uid, logId: dateStr);
      } catch (e) {
        debugPrint('Lỗi xóa log trên cloud: $e');
      }
    }
  }
}

final dailyLogProvider = StateNotifierProvider<DailyLogNotifier, List<DailyLogModel>>((ref) {
  final repo = ref.watch(dailyLogRepositoryProvider);
  return DailyLogNotifier(localRepo: repo, ref: ref);
});
