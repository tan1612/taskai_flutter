import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/chat_message.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/models/timetable_slot.dart';
import 'package:taskai/data/services/api_service.dart';

class GeminiRepository {
  final ApiService _apiService;

  GeminiRepository(this._apiService);

  Future<String> ask(
    List<ChatMessage> history, {
    List<TaskModel> tasks = const [],
    List<TimetableSlot> timetableSlots = const [],
    String? weatherContext,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final latestQuestion = history.last.content;

    if (apiKey.trim().isEmpty) {
      return _fallbackAnswer(latestQuestion, tasks, timetableSlots, weatherContext);
    }

    final taskContext = _buildTaskContext(tasks);
    final timetableContext = _buildTimetableContext(timetableSlots);
    final weatherText = _buildWeatherContext(weatherContext);

    final systemPrompt = '''
Bạn là TaskAI Pro, trợ lý học tập và di chuyển cá nhân thông minh bằng tiếng Việt của sinh viên.

Nhiệm vụ:
- Tư vấn cách sắp xếp công việc, mức độ ưu tiên dựa trên danh sách task thực tế của người dùng bên dưới.
- Tư vấn, đối chiếu lịch học (thời khóa biểu) của người dùng bên dưới khi được hỏi về lịch học hoặc khi lập kế hoạch học tập, sắp xếp lịch trình. Gợi ý lịch học đi kèm phòng học, thứ tự tiết học, giờ bắt đầu và giờ kết thúc môn học.
- Nếu người dùng hỏi "Hôm nay tôi nên làm gì trước?" hoặc "Lập kế hoạch học tập hôm nay": Hãy phân tích các task và lịch học của hôm nay, khuyên làm trước các task chưa xong có độ ưu tiên cao (High) hoặc deadline cận kề nhất, đồng thời nhắc nhở về các tiết học trong ngày hôm nay. Chia nhỏ công việc ra thành 3 bước nhỏ.
- Nếu người dùng hỏi "Task nào sắp trễ?": Cảnh báo về các task chưa xong đã quá deadline (trễ hạn) hoặc còn dưới 24h.
- Nếu người dùng hỏi "Thời tiết có ảnh hưởng gì không?": Liên kết thời tiết hiện tại/dự báo với lịch di chuyển của họ. Cảnh báo mang ô/áo mưa nếu trời mưa, khuyên mang mũ/nước nếu nắng nóng.
- Trả lời ngắn gọn, có cấu trúc bullet point rõ ràng, thân thiện. Không tự bịa task, lịch học hoặc thời tiết nếu dữ liệu không có.

$weatherText

$timetableContext

$taskContext
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map(
        (m) => {
          'role': m.role == ChatRole.user ? 'user' : 'assistant',
          'content': m.content,
        },
      ),
    ];

    try {
      final response = await _apiService.dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        },
      );

      final text =
          response.data['choices'][0]['message']['content']?.toString();

      if (text == null || text.trim().isEmpty) {
        return _fallbackAnswer(latestQuestion, tasks, timetableSlots, weatherContext);
      }

      return text.trim();
    } on DioException catch (e) {
      print('=== GROQ ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Body: ${e.response?.data}');
      return _fallbackAnswer(latestQuestion, tasks, timetableSlots, weatherContext);
    } catch (e) {
      print('=== UNKNOWN ERROR: $e ===');
      return _fallbackAnswer(latestQuestion, tasks, timetableSlots, weatherContext);
    }
  }

  String _buildWeatherContext(String? weatherContext) {
    if (weatherContext == null || weatherContext.trim().isEmpty) {
      return '''
=== THỜI TIẾT HIỆN TẠI & DỰ BÁO ===
Chưa có dữ liệu thời tiết được truyền vào chatbot.
''';
    }

    return '''
=== THỜI TIẾT HIỆN TẠI & DỰ BÁO ===
${weatherContext.trim()}
''';
  }

  String _buildTaskContext(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return '=== DANH SÁCH CÔNG VIỆC ===\nNgười dùng chưa có task nào.';
    }

    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    final pending = tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) {
        final aTime = a.isLocationTask && a.startTime != null
            ? a.startTime!
            : a.deadline;
        final bTime = b.isLocationTask && b.startTime != null
            ? b.startTime!
            : b.deadline;

        return aTime.compareTo(bTime);
      });

    final done = tasks.where((t) => t.isDone).toList();

    final buffer = StringBuffer();
    buffer.writeln('=== DANH SÁCH CÔNG VIỆC CỦA NGƯỜI DÙNG ===');
    buffer.writeln('Thời điểm hiện tại: ${fmt.format(now)}');
    buffer.writeln(
      'Tổng: ${tasks.length} task (${pending.length} chưa xong, ${done.length} hoàn thành)',
    );
    buffer.writeln();

    if (pending.isNotEmpty) {
      buffer.writeln('--- CHƯA HOÀN THÀNH ---');

      for (final t in pending) {
        buffer.writeln('• [${t.priority.label}] ${t.title}');
        buffer.writeln('  Loại: ${t.isLocationTask ? 'Có di chuyển' : 'Thông thường'}');

        if (t.isLocationTask) {
          if (t.startTime != null) {
            buffer.writeln('  Giờ bắt đầu: ${fmt.format(t.startTime!)}');
          }

          if (t.endTime != null) {
            buffer.writeln('  Giờ kết thúc: ${fmt.format(t.endTime!)}');
          }

          if (t.locationName != null && t.locationName!.trim().isNotEmpty) {
            buffer.writeln('  Địa điểm: ${t.locationName!.trim()}');
          }

          buffer.writeln('  Thời gian di chuyển dự kiến: ${t.travelMinutes} phút');

          final departureTime = t.departureTime;
          if (departureTime != null) {
            buffer.writeln('  Giờ nên xuất phát: ${fmt.format(departureTime)}');
          }
        } else {
          final diff = t.deadline.difference(now);
          String timeLeft;

          if (diff.isNegative) {
            timeLeft = '⚠️ Đã trễ ${(-diff.inHours)} giờ';
          } else if (diff.inHours < 24) {
            timeLeft = '🔥 Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút';
          } else {
            timeLeft = 'Còn ${diff.inDays} ngày';
          }

          buffer.writeln('  Deadline: ${fmt.format(t.deadline)} ($timeLeft)');
        }

        if (t.description.trim().isNotEmpty) {
          buffer.writeln('  Mô tả: ${t.description.trim()}');
        }

        if (t.tag.trim().isNotEmpty) {
          buffer.writeln('  Tag: ${t.tag.trim()}');
        }

        buffer.writeln();
      }
    }

    if (done.isNotEmpty) {
      buffer.writeln('--- ĐÃ HOÀN THÀNH ---');
      for (final t in done) {
        buffer.writeln('• ✅ ${t.title}');
      }
    }

    buffer.writeln('=== HẾT DANH SÁCH ===');
    return buffer.toString();
  }

  String _buildTimetableContext(List<TimetableSlot> slots) {
    if (slots.isEmpty) {
      return '=== THỜI KHÓA BIỂU HỌC TẬP ===\nNgười dùng chưa thêm môn học nào vào thời khóa biểu.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== THỜI KHÓA BIỂU HỌC TẬP CỦA NGƯỜI DÙNG ===');
    buffer.writeln('Tổng số môn học đăng ký: ${slots.length}');
    buffer.writeln();

    final sortedSlots = List<TimetableSlot>.from(slots)
      ..sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startPeriod.compareTo(b.startPeriod);
      });

    final daysMap = {
      1: 'Thứ 2',
      2: 'Thứ 3',
      3: 'Thứ 4',
      4: 'Thứ 5',
      5: 'Thứ 6',
      6: 'Thứ 7',
      7: 'Chủ Nhật',
    };

    final fmtDate = DateFormat('dd/MM/yyyy');

    for (final slot in sortedSlots) {
      final dayLabel = daysMap[slot.dayOfWeek] ?? 'Thứ ${slot.dayOfWeek}';
      buffer.writeln('• Môn học: ${slot.subjectName}');
      buffer.writeln('  Phòng học: ${slot.room}');
      buffer.writeln('  Ngày học: $dayLabel');
      buffer.writeln('  Thời gian: Tiết ${slot.startPeriod} - Tiết ${slot.endPeriod} (${slot.startTimeLabel} - ${slot.endTimeLabel})');
      buffer.writeln('  Giai đoạn học: Từ ${fmtDate.format(slot.startDate)} đến ${fmtDate.format(slot.endDate)}');
      buffer.writeln();
    }

    buffer.writeln('=== HẾT THỜI KHÓA BIỂU ===');
    return buffer.toString();
  }

  String _fallbackAnswer(
    String question,
    List<TaskModel> tasks,
    List<TimetableSlot> timetableSlots,
    String? weatherContext,
  ) {
    final lower = question.toLowerCase().trim();
    final now = DateTime.now();

    // 0. Ask about class timetable
    if (lower.contains('học') || lower.contains('thời khóa biểu') || lower.contains('môn') || lower.contains('lớp')) {
      if (timetableSlots.isEmpty) {
        return 'Trợ lý đang chạy ở chế độ offline: Bạn chưa thêm môn học nào vào thời khóa biểu học tập.';
      }
      final sortedSlots = List<TimetableSlot>.from(timetableSlots)
        ..sort((a, b) {
          if (a.dayOfWeek != b.dayOfWeek) {
            return a.dayOfWeek.compareTo(b.dayOfWeek);
          }
          return a.startPeriod.compareTo(b.startPeriod);
        });

      final daysMap = {
        1: 'Thứ 2',
        2: 'Thứ 3',
        3: 'Thứ 4',
        4: 'Thứ 5',
        5: 'Thứ 6',
        6: 'Thứ 7',
        7: 'Chủ Nhật',
      };

      final buffer = StringBuffer();
      buffer.writeln('Thời khóa biểu của bạn (Chế độ offline):');
      for (final slot in sortedSlots) {
        final dayLabel = daysMap[slot.dayOfWeek] ?? 'Thứ ${slot.dayOfWeek}';
        buffer.writeln('- **${slot.subjectName}** ($dayLabel, Phòng: ${slot.room}, Tiết: ${slot.startPeriod}-${slot.endPeriod} [${slot.startTimeLabel}-${slot.endTimeLabel}])');
      }
      return buffer.toString();
    }

    // 1. Ask what to do today
    if (lower.contains('làm gì') || lower.contains('kế hoạch') || lower.contains('gợi ý')) {
      final todayPending = tasks.where((t) {
        final compareDate = t.isLocationTask && t.startTime != null ? t.startTime! : t.deadline;
        return !t.isDone &&
            compareDate.year == now.year &&
            compareDate.month == now.month &&
            compareDate.day == now.day;
      }).toList();

      if (todayPending.isEmpty) {
        return 'Hệ thống đang offline, nhưng theo lịch lưu cục bộ: Bạn không có task chưa xong nào trong ngày hôm nay! Bạn có thể thư giãn hoặc tạo thêm task mới. 🎉';
      }

      todayPending.sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
      final topTask = todayPending.first;

      final buffer = StringBuffer();
      buffer.writeln('Trợ lý đang chạy ở chế độ offline. Gợi ý lịch trình hôm nay cho bạn:');
      buffer.writeln('Hôm nay bạn có ${todayPending.length} việc chưa hoàn thành.');
      buffer.writeln('👉 **Nên làm trước**: **${topTask.title}** [Ưu tiên: ${topTask.priority.label}]');
      if (topTask.description.isNotEmpty) {
        buffer.writeln('   Mô tả: ${topTask.description}');
      }
      buffer.writeln('\nDanh sách việc hôm nay:');
      for (final t in todayPending) {
        buffer.writeln('- [${t.priority.label}] ${t.title}');
      }
      return buffer.toString();
    }

    // 2. Ask about late/overdue tasks
    if (lower.contains('trễ') || lower.contains('hạn')) {
      final overdue = tasks.where((t) {
        final compareDate = t.isLocationTask && t.startTime != null ? t.startTime! : t.deadline;
        return !t.isDone && compareDate.isBefore(now);
      }).toList();

      if (overdue.isEmpty) {
        return 'Chúc mừng! Bạn không có công việc nào bị trễ hạn ở chế độ offline. 👍';
      }

      final buffer = StringBuffer();
      buffer.writeln('⚠️ Cảnh báo: Bạn đang có ${overdue.length} công việc trễ hạn:');
      for (final t in overdue) {
        final delay = now.difference(t.isLocationTask && t.startTime != null ? t.startTime! : t.deadline).inHours;
        buffer.writeln('- **${t.title}** (Đã trễ khoảng $delay giờ)');
      }
      buffer.writeln('\nHãy cố gắng hoàn thành sớm nhé!');
      return buffer.toString();
    }

    // 3. Ask about weather
    if (lower.contains('thời tiết') || lower.contains('mưa') || lower.contains('nắng')) {
      if (weatherContext != null && weatherContext.trim().isNotEmpty) {
        // Try to extract current weather
        final lines = weatherContext.split('\n');
        final currentInfo = lines.take(6).join('\n');
        return 'Cập nhật thời tiết ngoại tuyến của bạn:\n$currentInfo\n\n*Lưu ý: Do đang mất kết nối AI, tôi chỉ hiển thị thông tin thời tiết thô.*';
      }
      return 'Hiện tại ứng dụng đang mất kết nối mạng và không có sẵn dữ liệu thời tiết để phản hồi.';
    }

    // 4. Statistics request
    if (lower.contains('thống kê') || lower.contains('tỷ lệ')) {
      final total = tasks.length;
      final done = tasks.where((t) => t.isDone).length;
      final percent = total == 0 ? 0 : ((done / total) * 100).round();
      return 'Thống kê công việc hiện tại (Offline):\n'
          '- Tổng số công việc: $total\n'
          '- Đã hoàn thành: $done\n'
          '- Chưa hoàn thành: ${total - done}\n'
          '- Tỷ lệ hoàn thành: $percent%';
    }

    if (lower.isEmpty) {
      return 'Chào bạn! Mình có thể giúp gì cho bạn trong việc quản lý thời gian và thời khóa biểu?';
    }

    return 'Trợ lý TaskAI Pro đang hoạt động ở chế độ offline (mất kết nối mạng hoặc thiếu API key). Bạn có thể hỏi về các công việc hôm nay, lịch học thời khóa biểu, công việc trễ hạn, thống kê hoặc thời tiết hiện tại để mình trả lời nhanh nhé.';
  }
}