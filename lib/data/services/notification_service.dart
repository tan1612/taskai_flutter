import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'namai_trip_channel';
  static const String _channelName = 'Năm Ái Reminders';
  static const String _channelDescription =
      'Thông báo nhắc lịch chạy xe du lịch';

  Future<void> init() async {
    if (_initialized) return;

    // Cài đặt múi giờ địa phương
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Không cấu hình được múi giờ qua FlutterTimezone, dùng default Asia/Ho_Chi_Minh: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Người dùng bấm vào thông báo: ${response.payload}');
      },
    );

    // Tạo kênh Android nếu là Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
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
          ? Hive.box('settings').get('weeklyReminderEnabled') as bool? ?? true
          : true;
      if (weeklyEnabled) {
        await scheduleWeeklySundayReminder();
      }
    } catch (e) {
      debugPrint('Lỗi tự động đặt nhắc nhở hàng tuần lúc khởi tạo: $e');
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
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final isGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
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
        ticker: 'Du Lịch Năm Ái',
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
      'Du Lịch Năm Ái thông báo thử',
      'Nếu bạn thấy thông báo này thì notification đã hoạt động.',
      _notificationDetails,
      payload: 'test',
    );

    debugPrint('Đã gọi showTestNotification.');
  }

  Future<void> scheduleTripReminder(TripModel trip) async {
    await init();

    if (trip.status == 'cancelled' || trip.status == 'completed') {
      await cancelTripReminder(trip.id);
      return;
    }

    final notifyTime = trip.startTime.subtract(const Duration(hours: 1)); // Nhắc trước 1 tiếng
    if (notifyTime.isBefore(DateTime.now())) {
      debugPrint('Không đặt notification nhắc chuyến "${trip.customerName}" vì thời gian nhắc đã qua.');
      return;
    }

    final carTypeLabel = trip.carType == '7_seater' ? 'xe 7 chỗ' : 'xe 16 chỗ';
    final body = 'Đón khách ${trip.customerName} tại ${trip.pickupLocation} đi ${trip.destination}. Loại xe: $carTypeLabel. Giá chốt: ${trip.finalPrice}đ.';

    await _plugin.zonedSchedule(
      _safeNotificationId(trip.id),
      'Du Lịch Năm Ái: Nhắc lịch chạy xe',
      body,
      tz.TZDateTime.from(notifyTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: trip.id,
    );

    debugPrint('Đã đặt lịch nhắc chuyến đi của "${trip.customerName}" trước 1 tiếng.');
  }

  Future<void> cancelTripReminder(String tripId) async {
    await init();
    await _plugin.cancel(_safeNotificationId(tripId));
    debugPrint('Đã hủy lịch nhắc chuyến đi ID: $tripId.');
  }

  Future<void> scheduleWeeklySundayReminder() async {
    final scheduledTime = _nextInstanceOfSundaySevenPM();

    await _plugin.zonedSchedule(
      10002, // Unique ID for weekly reminder
      'Du Lịch Năm Ái: Lên lịch tuần mới',
      'Đã đến lúc cập nhật và sắp xếp lịch đặt xe cho tuần tới rồi bạn ơi! 🚀',
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

    // Sử dụng Future.delayed để hiển thị thông báo thử nhằm tránh giới hạn của iOS/TrollStore đối với zonedSchedule
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await _plugin.show(
          10003, // Unique test ID
          'Du Lịch Năm Ái: Lên lịch tuần mới (Test)',
          'Đã đến lúc cập nhật và sắp xếp lịch đặt xe cho tuần tới rồi bạn ơi! 🚀 (Thông báo thử)',
          _notificationDetails,
        );
        debugPrint('=== WEEKLY REMINDER TEST ===: Đã hiển thị thông báo thử.');
      } catch (e) {
        debugPrint('Lỗi hiển thị thông báo thử: $e');
      }
    });

    debugPrint('=== WEEKLY REMINDER TEST ===: Đã hẹn giờ hiển thị thông báo test sau 10 giây.');
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
}