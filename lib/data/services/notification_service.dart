import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'taskai_deadline_channel';
  static const String _channelName = 'TaskAI Reminders';
  static const String _channelDescription =
      'Thông báo nhắc công việc và lịch di chuyển';

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await androidPlugin?.createNotificationChannel(channel);

    if (!kIsWeb && Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('iOS notification permission granted: $granted');
    }

    _initialized = true;
  }

  NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'TaskAI',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  int _safeNotificationId(String value) {
    return value.hashCode & 0x7fffffff;
  }

  Future<void> showTestNotification() async {
    await init();

    await _plugin.show(
      10001,
      'TaskAI thông báo thử',
      'Nếu bạn thấy thông báo này thì notification đã hoạt động.',
      _notificationDetails,
      payload: 'test',
    );

    debugPrint('Đã gọi showTestNotification.');
  }

  Future<void> scheduleTaskReminder(TaskModel task) async {
    await init();

    if (task.isDone) return;

    if (task.isLocationTask) {
      await _scheduleLocationTaskReminder(task);
    } else {
      await _scheduleNormalTaskReminder(task);
    }
  }

  Future<void> _scheduleNormalTaskReminder(TaskModel task) async {
    final reminderMinutes = task.reminderMinutes;

    if (reminderMinutes == 0) {
      debugPrint('Task "${task.title}" không bật nhắc deadline.');
      return;
    }

    if (reminderMinutes == -1) {
      await _scheduleDemoAfter10Seconds(task);
      return;
    }

    final scheduledTime = task.deadline.subtract(
      Duration(minutes: reminderMinutes),
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint(
        'Không đặt notification cho "${task.title}" vì thời gian nhắc đã qua.',
      );
      return;
    }

    await _plugin.zonedSchedule(
      _safeNotificationId(task.id),
      'TaskAI nhắc deadline',
      'Còn $reminderMinutes phút đến deadline: ${task.title}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    debugPrint(
      'Đã đặt notification deadline cho "${task.title}" trước $reminderMinutes phút.',
    );
  }

  Future<void> _scheduleLocationTaskReminder(TaskModel task) async {
    final reminderMinutes = task.reminderMinutes;

    if (reminderMinutes == 0) {
      debugPrint('Task "${task.title}" không bật nhắc di chuyển.');
      return;
    }

    if (reminderMinutes == -1) {
      await _scheduleDemoAfter10Seconds(task);
      return;
    }

    final departureTime = task.departureTime;
    final notifyTime = task.departureNotificationTime;

    if (departureTime == null || notifyTime == null) {
      debugPrint('Không đặt notification cho "${task.title}" vì thiếu giờ bắt đầu.');
      return;
    }

    if (notifyTime.isBefore(DateTime.now())) {
      debugPrint(
        'Không đặt notification cho "${task.title}" vì thời gian nhắc đã qua.',
      );
      return;
    }

    final departureLabel = _formatTime(departureTime);

    await _plugin.zonedSchedule(
      _safeNotificationId(task.id),
      'TaskAI nhắc di chuyển',
      'Bạn nên đi lúc $departureLabel. '
          'Từ ${task.effectiveOrigin} đến ${task.effectiveDestination} '
          'khoảng ${task.travelMinutes} phút.',
      tz.TZDateTime.from(notifyTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    debugPrint(
      'Đã đặt notification di chuyển cho "${task.title}". '
      'Xuất phát lúc $departureLabel, nhắc trước ${task.departReminderMinutes} phút.',
    );
  }

  Future<void> _scheduleDemoAfter10Seconds(TaskModel task) async {
    await init();

    final title = task.isLocationTask
        ? 'TaskAI nhắc di chuyển'
        : 'TaskAI nhắc deadline';

    final body = task.isLocationTask
        ? 'Bạn nên đi từ ${task.effectiveOrigin} đến ${task.effectiveDestination}. '
            'Thời gian di chuyển khoảng ${task.travelMinutes} phút.'
        : 'Task demo: ${task.title}';

    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    await _plugin.zonedSchedule(
      _safeNotificationId(task.id),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    debugPrint('Đã đặt demo notification thật sau 10 giây cho task "${task.title}".');
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await init();
    await _plugin.cancel(_safeNotificationId(taskId));
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}