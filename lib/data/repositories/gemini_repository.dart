import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/chat_message.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/data/services/api_service.dart';

class GeminiRepository {
  final ApiService _apiService;

  GeminiRepository(this._apiService);

  Future<String> ask(
    List<ChatMessage> history, {
    List<TaskModel> tasks = const [],
    String? weatherContext,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final latestQuestion = history.last.content;

    if (apiKey.trim().isEmpty) {
      return _fallbackAnswer(latestQuestion);
    }

    final taskContext = _buildTaskContext(tasks);
    final weatherText = _buildWeatherContext(weatherContext);

    final systemPrompt = '''
Bạn là TaskAI, trợ lý quản lý công việc thông minh bằng tiếng Việt.

Nhiệm vụ:
- Tư vấn cách sắp xếp deadline dựa trên danh sách task thực tế của người dùng.
- Nếu có dữ liệu thời tiết, hãy dùng thời tiết để tư vấn việc đi học, đi làm, đi ra ngoài, di chuyển.
- Với task có di chuyển, hãy chú ý giờ bắt đầu, thời gian di chuyển dự kiến, giờ nên xuất phát.
- Chia nhỏ công việc thành bước cụ thể.
- Ưu tiên câu trả lời ngắn gọn, thực tế, dễ làm.
- Khi người dùng hỏi về task, công việc, lịch trình, thời tiết — hãy dựa vào dữ liệu bên dưới để trả lời chính xác.
- Không tự bịa task hoặc thời tiết nếu dữ liệu không có.

$weatherText

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
        return _fallbackAnswer(latestQuestion);
      }

      return text.trim();
    } on DioException catch (e) {
      print('=== GROQ ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Body: ${e.response?.data}');
      return _fallbackAnswer(latestQuestion);
    } catch (e) {
      print('=== UNKNOWN ERROR: $e ===');
      return _fallbackAnswer(latestQuestion);
    }
  }

  String _buildWeatherContext(String? weatherContext) {
    if (weatherContext == null || weatherContext.trim().isEmpty) {
      return '''
=== THỜI TIẾT HIỆN TẠI ===
Chưa có dữ liệu thời tiết được truyền vào chatbot.
Nếu người dùng hỏi thời tiết, hãy nói rằng hiện chưa đọc được thời tiết trong chatbot.
''';
    }

    return '''
=== THỜI TIẾT HIỆN TẠI ===
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

          if (t.locationAddress != null &&
              t.locationAddress!.trim().isNotEmpty) {
            buffer.writeln('  Địa chỉ/ghi chú: ${t.locationAddress!.trim()}');
          }

          buffer.writeln('  Thời gian di chuyển dự kiến: ${t.travelMinutes} phút');

          final departureTime = t.departureTime;
          final notifyTime = t.departureNotificationTime;

          if (departureTime != null) {
            buffer.writeln('  Giờ nên xuất phát: ${fmt.format(departureTime)}');
          }

          if (notifyTime != null && t.reminderMinutes != 0) {
            if (t.reminderMinutes == -1) {
              buffer.writeln('  Nhắc di chuyển: Demo sau 10 giây');
            } else {
              buffer.writeln('  Giờ thông báo dự kiến: ${fmt.format(notifyTime)}');
            }
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

          if (t.reminderMinutes == 0) {
            buffer.writeln('  Nhắc deadline: Không nhắc');
          } else if (t.reminderMinutes == -1) {
            buffer.writeln('  Nhắc deadline: Demo sau 10 giây');
          } else {
            buffer.writeln('  Nhắc trước deadline: ${t.reminderMinutes} phút');
          }
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

  String _fallbackAnswer(String question) {
    final lower = question.toLowerCase().trim();

    if (lower.isEmpty) {
      return 'Bạn hãy nhập công việc hoặc câu hỏi cụ thể, mình sẽ giúp bạn sắp xếp kế hoạch hợp lý.';
    }

    if (_containsAny(lower, ['xin chào', 'chào', 'hello', 'hi'])) {
      return 'Xin chào! Mình là TaskAI. Mình có thể giúp bạn lập kế hoạch, chia nhỏ công việc, ưu tiên deadline và gợi ý cách làm việc hiệu quả hơn.';
    }

    if (_containsAny(lower, ['thời tiết', 'mưa', 'nắng', 'trời'])) {
      return 'Hiện mình chưa đọc được dữ liệu thời tiết trong chatbot. Bạn cần truyền dữ liệu thời tiết từ Weather API vào chatbot để mình tư vấn chính xác hơn.';
    }

    if (_containsAny(lower, ['ưu tiên', 'quan trọng', 'nên làm gì trước'])) {
      return 'Để ưu tiên công việc: 1) Làm trước task deadline gần nhất. 2) Nếu nhiều task cùng hạn, chọn task ưu tiên cao hơn. 3) Chỉ chọn 3 việc quan trọng nhất mỗi ngày.';
    }

    if (_containsAny(lower, ['deadline', 'hạn', 'trễ'])) {
      return 'Để tránh trễ deadline: chia task thành mốc 25 phút, làm phần khó nhất trước, nếu quá gấp thì ưu tiên bản tối thiểu có thể nộp trước.';
    }

    return 'Mình đang mất kết nối. Hãy cho mình biết công việc, deadline và mức độ ưu tiên, mình sẽ giúp bạn lập kế hoạch.';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}