import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskai/data/models/task_model.dart';

class CloudTaskRepository {
  final FirebaseFirestore firestore;

  CloudTaskRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> _collection(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) {
      return firestore.collection('users').doc(userId.trim()).collection('tasks');
    }
    return firestore.collection('tasks');
  }

  Future<void> upsert(TaskModel task, {String? userId}) async {
    final effectiveUid = userId ?? task.userId;
    await _collection(effectiveUid).doc(task.id).set(
          _toMap(task, effectiveUid),
          SetOptions(merge: true),
        );
  }

  Future<void> delete(String taskId, {String? userId}) async {
    await _collection(userId).doc(taskId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> taskStream({String? userId}) {
    return _collection(userId).snapshots();
  }

  TaskModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return fromMap(map);
  }

  TaskModel fromMap(Map<String, dynamic> map) {
    DateTime parseTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseOptionalTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    TaskPriority parsePriority(String? name) {
      if (name == null) return TaskPriority.medium;
      return TaskPriority.values.firstWhere(
        (e) => e.name == name,
        orElse: () => TaskPriority.medium,
      );
    }

    TaskType parseType(String? name) {
      if (name == null) return TaskType.normal;
      return TaskType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => TaskType.normal,
      );
    }

    return TaskModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Không có tiêu đề',
      description: map['description']?.toString() ?? '',
      deadline: parseTime(map['deadline'], DateTime.now()),
      priority: parsePriority(map['priority']?.toString()),
      tag: map['tag']?.toString() ?? 'Khác',
      isDone: map['isDone'] as bool? ?? false,
      createdAt: parseTime(map['createdAt'], DateTime.now()),
      reminderMinutes: (map['reminderMinutes'] as num?)?.toInt() ?? 60,
      type: parseType(map['type']?.toString()),
      startTime: parseOptionalTime(map['startTime']),
      endTime: parseOptionalTime(map['endTime']),
      locationName: map['locationName']?.toString(),
      locationAddress: map['locationAddress']?.toString(),
      googleMapsUrl: map['googleMapsUrl']?.toString(),
      originName: map['originName']?.toString(),
      destinationName: map['destinationName']?.toString(),
      travelMinutes: (map['travelMinutes'] as num?)?.toInt() ?? 30,
      departReminderMinutes: (map['departReminderMinutes'] as num?)?.toInt() ?? 10,
      syncStatus: 'synced',
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(TaskModel task, String? effectiveUid) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'deadline': Timestamp.fromDate(task.deadline),
      'priority': task.priority.name,
      'tag': task.tag,
      'isDone': task.isDone,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'reminderMinutes': task.reminderMinutes,
      'type': task.type.name,
      'startTime':
          task.startTime == null ? null : Timestamp.fromDate(task.startTime!),
      'endTime': task.endTime == null ? null : Timestamp.fromDate(task.endTime!),
      'locationName': task.locationName,
      'locationAddress': task.locationAddress,
      'googleMapsUrl': task.googleMapsUrl,
      'originName': task.originName,
      'destinationName': task.destinationName,
      'travelMinutes': task.travelMinutes,
      'departReminderMinutes': task.departReminderMinutes,
      'userId': effectiveUid,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}