import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taskai/data/models/task_model.dart';

class EmailService {
  static final Dio _dio = Dio();

  static Future<bool> sendHighPriorityTaskAlert(TaskModel task, String userEmail) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';
    
    final envEmail = dotenv.env['RECEIVER_EMAIL'] ?? '';
    final receiverEmail = envEmail.trim().isNotEmpty ? envEmail : userEmail;

    if (serviceId.trim().isEmpty || 
        templateId.trim().isEmpty || 
        publicKey.trim().isEmpty || 
        receiverEmail.trim().isEmpty) {
      print('=== EMAIL ALERT ===: Chưa cấu hình đầy đủ key EmailJS trong .env. Bỏ qua gửi email.');
      return false;
    }

    try {
      final deadlineStr = task.isLocationTask && task.startTime != null
          ? 'Lịch di chuyển - Bắt đầu lúc: ${task.startTime!.toLocal()}'
          : 'Hạn chót: ${task.deadline.toLocal()}';

      print('=== EMAIL ALERT ===: Đang gửi email cảnh báo đến $receiverEmail...');

      final response = await _dio.post(
        'https://api.emailjs.com/api/v1.0/email/send',
        data: {
          'service_id': serviceId.trim(),
          'template_id': templateId.trim(),
          'user_id': publicKey.trim(),
          'template_params': {
            'task_title': task.title,
            'task_description': task.description.isEmpty ? 'Không có mô tả' : task.description,
            'task_deadline': deadlineStr,
            'task_priority': task.priority.label,
            'task_tag': task.tag,
            'receiver_email': receiverEmail.trim(),
          }
        },
      );

      if (response.statusCode == 200) {
        print('=== EMAIL ALERT ===: Gửi email cảnh báo công việc độ ưu tiên cao đến $receiverEmail thành công!');
        return true;
      } else {
        print('=== EMAIL ALERT ===: Gửi email đến $receiverEmail thất bại. Mã lỗi: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      print('=== EMAIL ALERT ERROR ===: Lỗi kết nối gửi email đến $receiverEmail: $e');
      return false;
    }
  }

  static Future<bool> sendWeeklyPlanningEmailAlert(String userEmail) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';
    
    final envEmail = dotenv.env['RECEIVER_EMAIL'] ?? '';
    final receiverEmail = envEmail.trim().isNotEmpty ? envEmail : userEmail;

    if (serviceId.trim().isEmpty || 
        templateId.trim().isEmpty || 
        publicKey.trim().isEmpty || 
        receiverEmail.trim().isEmpty) {
      print('=== EMAIL ALERT ===: Chưa cấu hình đầy đủ key EmailJS trong .env. Bỏ qua gửi email.');
      return false;
    }

    try {
      print('=== WEEKLY EMAIL ALERT ===: Đang gửi email nhắc lên lịch tuần mới đến $receiverEmail...');

      final response = await _dio.post(
        'https://api.emailjs.com/api/v1.0/email/send',
        data: {
          'service_id': serviceId.trim(),
          'template_id': templateId.trim(),
          'user_id': publicKey.trim(),
          'template_params': {
            'task_title': 'Lên kế hoạch tuần mới cùng TaskAI Pro! 🚀',
            'task_description': 'Đã đến lúc cập nhật và sắp xếp công việc cho tuần tới rồi bạn ơi! Hãy mở ứng dụng TaskAI để chuẩn bị một tuần mới thật năng suất nhé.',
            'task_deadline': 'Mỗi 19h Chủ Nhật hàng tuần',
            'task_priority': 'Cao',
            'task_tag': 'Hệ thống',
            'receiver_email': receiverEmail.trim(),
          }
        },
      );

      if (response.statusCode == 200) {
        print('=== WEEKLY EMAIL ALERT ===: Gửi email nhắc tuần mới đến $receiverEmail thành công!');
        return true;
      } else {
        print('=== WEEKLY EMAIL ALERT ===: Gửi email thất bại. Mã lỗi: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      print('=== WEEKLY EMAIL ALERT ERROR ===: Lỗi kết nối gửi email tuần mới đến $receiverEmail: $e');
      return false;
    }
  }
}
