import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/models/timetable_slot.dart';
import 'package:taskai/data/repositories/weather_repository.dart';
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

    // Lấy múi giờ hệ thống để tránh lệch giờ khi lên lịch định kỳ
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Đã cấu hình múi giờ hệ thống: $timeZoneName');
    } catch (e) {
      debugPrint('Lỗi lấy múi giờ hệ thống, sử dụng Asia/Ho_Chi_Minh làm mặc định: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (ex) {
        debugPrint('Không thể đặt Asia/Ho_Chi_Minh: $ex');
      }
    }

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

    try {
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('=== NOTIFICATION ===: Quyền thông báo Android: $granted');
    } catch (e) {
      debugPrint('=== NOTIFICATION ===: Lỗi yêu cầu quyền thông báo: $e');
    }

    try {
      final grantedExact = await androidPlugin?.requestExactAlarmsPermission();
      debugPrint('=== NOTIFICATION ===: Quyền exact alarm Android: $grantedExact');
    } catch (e) {
      debugPrint('=== NOTIFICATION ===: Lỗi yêu cầu quyền exact alarm: $e');
    }

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

    // Kiểm tra cài đặt và đặt/hủy lịch nhắc nhở Chủ nhật 19:00
    try {
      final weeklyEnabled = Hive.isBoxOpen('settings')
          ? (Hive.box('settings').get('weeklyReminderEnabled') as bool? ?? true)
          : true;
      if (weeklyEnabled) {
        await scheduleWeeklySundayReminder();
      } else {
        await cancelWeeklySundayReminder();
      }
    } catch (e) {
      debugPrint('Lỗi cấu hình nhắc nhở hàng tuần: $e');
    }
  }

  Future<bool> checkPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final isGranted = await androidPlugin?.areNotificationsEnabled() ?? false;
      return isGranted;
    }
    return true;
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

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Quyền thông báo chưa được cấp. Vui lòng mở cài đặt thiết bị để cho phép thông báo.');
    }

    await _plugin.show(
      10001,
      'TaskAI thông báo thử',
      'Nếu bạn thấy thông báo này thì notification đã hoạt động.',
      _notificationDetails,
      payload: 'test',
    );

    debugPrint('Đã gọi showTestNotification.');
  }

  Future<void> scheduleTaskReminder(TaskModel task, {WeatherRepository? weatherRepository}) async {
    await init();

    if (task.isDone) return;

    if (task.isLocationTask) {
      await _scheduleLocationTaskReminder(task, weatherRepository: weatherRepository);
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

  Future<void> _scheduleLocationTaskReminder(TaskModel task, {WeatherRepository? weatherRepository}) async {
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
    String weatherText = '';

    if (weatherRepository != null && task.effectiveDestination != 'Điểm đến') {
      try {
        final forecast = await weatherRepository.getForecastWeather(city: task.effectiveDestination);
        final targetTime = task.startTime ?? task.deadline;
        final closestItem = forecast.nearestTo(targetTime);

        if (closestItem != null) {
          final diff = closestItem.time.difference(targetTime).abs();
          // Nếu mốc dự báo gần nhất nằm trong vòng 12 tiếng
          if (diff.inHours < 12) {
            final temp = closestItem.temperature.round();
            final desc = closestItem.description;

            // Phân tích điều kiện để đưa ra gợi ý di chuyển tốt nhất
            String recommendation = 'Thời tiết thuận tiện cho việc di chuyển.';
            final lowerDesc = desc.toLowerCase();
            if (lowerDesc.contains('mưa') || lowerDesc.contains('dông') || lowerDesc.contains('phùn')) {
              recommendation = 'Có mưa, nên mang theo ô/áo mưa và đi chậm cẩn thận!';
            } else if (closestItem.temperature > 33) {
              recommendation = 'Trời nắng nóng gay gắt, mang theo nước uống và mũ nón!';
            } else if (closestItem.windSpeed > 8) {
              recommendation = 'Gió mạnh, chú ý lái xe vững tay lái!';
            } else if (lowerDesc.contains('nắng') || lowerDesc.contains('quang') || lowerDesc.contains('đẹp')) {
              recommendation = 'Trời nắng ráo, rất thích hợp để di chuyển.';
            }

            weatherText = '\nDự báo thời tiết tại ${task.effectiveDestination}: ${temp}°C, $desc. Gợi ý: $recommendation';
          }
        }
      } catch (e) {
        debugPrint('Không thể lấy thời tiết dự báo cho thông báo di chuyển: $e');
      }
    }

    String body = 'Bạn nên đi lúc $departureLabel. '
        'Từ ${task.effectiveOrigin} đến ${task.effectiveDestination} '
        'khoảng ${task.travelMinutes} phút.';
        
    if (weatherText.isNotEmpty) {
      body += weatherText;
    }

    await _plugin.zonedSchedule(
      _safeNotificationId(task.id),
      'TaskAI nhắc di chuyển',
      body,
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

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    await _plugin.zonedSchedule(
      _safeNotificationId(task.id),
      title,
      body,
      scheduledTime,
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

  Future<void> scheduleWeeklySundayReminder() async {
    final scheduledTime = _nextInstanceOfSundaySevenPM();

    await _plugin.zonedSchedule(
      10002, // Unique ID for weekly reminder
      'TaskAI Pro: Lên lịch tuần mới',
      'Đã đến lúc cập nhật và sắp xếp công việc cho tuần tới rồi bạn ơi! 🚀',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint('=== WEEKLY REMINDER ===: Đã đặt lịch nhắc Chủ nhật lúc 19:00 thành công.');
  }

  Future<void> cancelWeeklySundayReminder() async {
    await init();
    await _plugin.cancel(10002);
    debugPrint('=== WEEKLY REMINDER ===: Đã hủy lịch nhắc hàng tuần.');
  }

  Future<void> scheduleWeeklyReminderTestAfter10Seconds() async {
    await init();
    
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Quyền thông báo chưa được cấp. Vui lòng mở cài đặt thiết bị để cho phép thông báo.');
    }

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    await _plugin.zonedSchedule(
      10003, // Unique test ID
      'TaskAI Pro: Lên lịch tuần mới (Test)',
      'Đã đến lúc cập nhật và sắp xếp công việc cho tuần tới rồi bạn ơi! 🚀 (Thông báo thử)',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('=== WEEKLY REMINDER TEST ===: Đã đặt lịch nhắc test sau 10 giây.');
  }

  tz.TZDateTime _nextInstanceOfSundaySevenPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0);
    
    // Find next Sunday (Sunday is day 7 in DateTime)
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // If it's already past 19:00 on Sunday, schedule for next Sunday
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }

  Future<void> scheduleTimetableSlotReminder(TimetableSlot slot) async {
    await init();

    final now = DateTime.now();
    if (now.isAfter(slot.endDate)) {
      debugPrint('=== TIMETABLE REMINDER ===: Môn "${slot.subjectName}" đã kết thúc vào ${slot.endDate}, không đặt lịch nhắc.');
      return;
    }

    final parts = slot.startTimeLabel.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final classTimeToday = DateTime(2026, 6, 1, hour, minute);
    final reminderTimeToday = classTimeToday.subtract(const Duration(hours: 1));

    int targetDayOfWeek = slot.dayOfWeek;
    if (reminderTimeToday.day != classTimeToday.day) {
      targetDayOfWeek = slot.dayOfWeek - 1;
      if (targetDayOfWeek < 1) targetDayOfWeek = 7;
    }

    final reminderHour = reminderTimeToday.hour;
    final reminderMinute = reminderTimeToday.minute;

    final scheduledTime = _nextInstanceOfDayOfWeekAndTime(
      targetDayOfWeek,
      reminderHour,
      reminderMinute,
    );

    final notifId = 20000 + _safeNotificationId(slot.id);

    await _plugin.zonedSchedule(
      notifId,
      'Sắp đến giờ học: ${slot.subjectName}',
      'Lớp học diễn ra lúc ${slot.startTimeLabel} tại phòng ${slot.room}. Đừng trễ nhé! 📚',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint('=== TIMETABLE REMINDER ===: Đã đặt lịch nhắc môn "${slot.subjectName}" trước 1 giờ.');
  }

  Future<void> cancelTimetableSlotReminder(String slotId) async {
    await init();
    final notifId = 20000 + _safeNotificationId(slotId);
    await _plugin.cancel(notifId);
    debugPrint('=== TIMETABLE REMINDER ===: Đã hủy lịch nhắc môn ID: $slotId.');
  }

  Future<void> scheduleTimetableSlotTestAfter10Seconds(TimetableSlot slot) async {
    await init();

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Quyền thông báo chưa được cấp. Vui lòng mở cài đặt thiết bị để cho phép thông báo.');
    }

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    final notifId = 30000 + _safeNotificationId(slot.id);

    await _plugin.zonedSchedule(
      notifId,
      'Sắp đến giờ học: ${slot.subjectName} (Test)',
      'Lớp học diễn ra lúc ${slot.startTimeLabel} tại phòng ${slot.room}. Đừng trễ nhé! 📚 (Thông báo thử)',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('=== TIMETABLE TEST REMINDER ===: Đã đặt lịch nhắc test 10 giây cho môn "${slot.subjectName}".');
  }

  tz.TZDateTime _nextInstanceOfDayOfWeekAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }
}