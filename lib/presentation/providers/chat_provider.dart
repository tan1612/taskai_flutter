import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/chat_message.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/task_provider.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
  });

  factory ChatState.initial() {
    return ChatState(
      messages: [
        ChatMessage(
          role: ChatRole.assistant,
          content:
              'Xin chào! Mình là TaskAI. Bạn có thể hỏi mình cách sắp xếp công việc, chia nhỏ deadline, xem lịch di chuyển hoặc hỏi thời tiết để lên kế hoạch.',
          createdAt: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(ChatState.initial());

  Future<void> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: clean,
      createdAt: DateTime.now(),
    );

    final history = [...state.messages, userMessage];

    state = state.copyWith(
      messages: history,
      isLoading: true,
      error: null,
    );

    try {
      final tasks = ref.read(taskProvider);
      final weatherContext = await _loadWeatherContext(tasks);

      final answer = await ref.read(geminiRepositoryProvider).ask(
            history,
            tasks: tasks,
            weatherContext: weatherContext,
          );

      final assistantMessage = ChatMessage(
        role: ChatRole.assistant,
        content: answer,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...history, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> _loadWeatherContext(List<TaskModel> tasks) async {
    try {
      final current = await ref.read(weatherProvider.future);
      final forecast = await ref.read(forecastWeatherProvider.future);

      final buffer = StringBuffer();

      buffer.writeln('Thời tiết hiện tại tại ${current.cityName}:');
      buffer.writeln('- Nhiệt độ: ${current.temperature.toStringAsFixed(1)}°C');
      buffer.writeln('- Trạng thái: ${current.description}');
      buffer.writeln('- Độ ẩm: ${current.humidity}%');
      buffer.writeln('- Tốc độ gió: ${current.windSpeed.toStringAsFixed(1)} m/s');
      buffer.writeln();

      final upcomingTasks = tasks.where((task) => !task.isDone).toList()
        ..sort((a, b) {
          final aTime = _targetWeatherTime(a);
          final bTime = _targetWeatherTime(b);
          return aTime.compareTo(bTime);
        });

      if (upcomingTasks.isEmpty) {
        buffer.writeln('Dự báo theo lịch: Người dùng chưa có task sắp tới.');
        return buffer.toString();
      }

      buffer.writeln('Dự báo thời tiết gần giờ các task sắp tới:');

      for (final task in upcomingTasks.take(8)) {
        final targetTime = _targetWeatherTime(task);
        final nearest = forecast.nearestTo(targetTime);

        if (nearest == null) continue;

        buffer.writeln('- Task: ${task.title}');
        buffer.writeln('  Loại: ${task.isLocationTask ? 'Có di chuyển' : 'Thông thường'}');

        if (task.isLocationTask) {
          if (task.startTime != null) {
            buffer.writeln('  Giờ bắt đầu lịch: ${_formatDateTime(task.startTime!)}');
          }

          final departureTime = task.departureTime;
          if (departureTime != null) {
            buffer.writeln('  Giờ nên xuất phát: ${_formatDateTime(departureTime)}');
          }

          buffer.writeln('  Thời gian di chuyển dự kiến: ${task.travelMinutes} phút');

          if (task.locationName != null && task.locationName!.trim().isNotEmpty) {
            buffer.writeln('  Địa điểm: ${task.locationName!.trim()}');
          }
        } else {
          buffer.writeln('  Deadline: ${_formatDateTime(task.deadline)}');
        }

        buffer.writeln('  Mốc dự báo gần nhất: ${_formatDateTime(nearest.time)}');
        buffer.writeln('  Dự báo: ${nearest.description}, ${nearest.temperature.toStringAsFixed(1)}°C, độ ẩm ${nearest.humidity}%, gió ${nearest.windSpeed.toStringAsFixed(1)} m/s');
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      return 'Không lấy được dữ liệu thời tiết/dự báo từ OpenWeatherMap. Lỗi: $e';
    }
  }

  DateTime _targetWeatherTime(TaskModel task) {
    if (task.isLocationTask) {
      return task.departureTime ?? task.startTime ?? task.deadline;
    }

    return task.deadline;
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});