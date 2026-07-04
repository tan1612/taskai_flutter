import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/chat_message.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
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
              'Xin chào! Mình là Trợ lý ảo Du Lịch Năm Ái. Bạn có thể hỏi mình về lịch đón khách hôm nay, tình trạng xe rảnh/bận, dự toán doanh thu, giá xăng dầu hoặc thời tiết để chạy xe nhé.',
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
      final trips = ref.read(tripProvider);
      final cars = ref.read(carProvider);
      final fuelPrices = ref.read(fuelPriceProvider);
      final dailyLogs = ref.read(dailyLogProvider);
      final weatherContext = await _loadWeatherContext(trips);

      final answer = await ref.read(geminiRepositoryProvider).ask(
            history,
            trips: trips,
            cars: cars,
            fuelPrices: fuelPrices,
            weatherContext: weatherContext,
            dailyLogs: dailyLogs,
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

  Future<String> _loadWeatherContext(List<TripModel> trips) async {
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

      final upcomingTrips = trips.where((trip) => trip.status != 'cancelled' && trip.status != 'completed').toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (upcomingTrips.isEmpty) {
        buffer.writeln('Dự báo theo lịch: Chưa có chuyến xe sắp tới.');
        return buffer.toString();
      }

      buffer.writeln('Dự báo thời tiết gần giờ các chuyến xe sắp tới:');

      for (final trip in upcomingTrips.take(5)) {
        final targetTime = trip.startTime;
        final nearest = forecast.nearestTo(targetTime);

        if (nearest == null) continue;

        buffer.writeln('- Khách: ${trip.customerName}');
        buffer.writeln('  Giờ đón: ${_formatDateTime(trip.startTime)}');
        buffer.writeln('  Lộ trình: ${trip.pickupLocation} -> ${trip.destination}');
        buffer.writeln('  Mốc thời tiết dự báo: ${_formatDateTime(nearest.time)}');
        buffer.writeln('  Dự báo: ${nearest.description}, ${nearest.temperature.toStringAsFixed(1)}°C');
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      return 'Không lấy được dữ liệu thời tiết/dự báo từ OpenWeatherMap. Lỗi: $e';
    }
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