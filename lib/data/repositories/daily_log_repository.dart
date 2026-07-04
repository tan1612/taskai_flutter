import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:taskai/data/models/daily_log_model.dart';

class DailyLogRepository {
  final Box<DailyLogModel> _localBox;

  DailyLogRepository(this._localBox);

  List<DailyLogModel> getAllLogs() {
    return _localBox.values.toList();
  }

  DailyLogModel? getLogByDate(String dateStr) {
    return _localBox.get(dateStr);
  }

  Future<void> saveLogLocally(DailyLogModel log) async {
    await _localBox.put(log.id, log);
  }

  Future<void> deleteLogLocally(String logId) async {
    await _localBox.delete(logId);
  }
}

class CloudDailyLogRepository {
  final FirebaseFirestore _firestore;

  CloudDailyLogRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _userLogsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('daily_logs');
  }

  Future<void> saveLogToCloud({
    required String userId,
    required DailyLogModel log,
  }) async {
    try {
      final cloudData = log.toMap();
      await _userLogsCollection(userId).doc(log.id).set(cloudData);
    } catch (e) {
      debugPrint('Lỗi khi lưu log lên cloud: $e');
      rethrow;
    }
  }

  Future<void> deleteLogFromCloud({
    required String userId,
    required String logId,
  }) async {
    try {
      await _userLogsCollection(userId).doc(logId).delete();
    } catch (e) {
      debugPrint('Lỗi khi xóa log trên cloud: $e');
      rethrow;
    }
  }

  Stream<List<DailyLogModel>> logStream({required String userId}) {
    return _userLogsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DailyLogModel.fromMap(doc.data());
      }).toList();
    });
  }
}
