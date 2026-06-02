import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskai/data/models/task_model.dart';

class CloudTaskRepository {
  final FirebaseFirestore firestore;

  CloudTaskRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    return firestore.collection('tasks');
  }

  Future<void> upsert(TaskModel task) async {
    await _tasksCollection.doc(task.id).set(
          _toMap(task),
          SetOptions(merge: true),
        );
  }

  Future<void> delete(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  Map<String, dynamic> _toMap(TaskModel task) {
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
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}