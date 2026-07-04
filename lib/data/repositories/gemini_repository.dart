import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/chat_message.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/data/models/fuel_price_model.dart';
import 'package:taskai/data/models/daily_log_model.dart';
import 'package:taskai/data/services/api_service.dart';

class GeminiRepository {
  final ApiService _apiService;

  GeminiRepository(this._apiService);

  Future<String> ask(
    List<ChatMessage> history, {
    List<TripModel> trips = const [],
    List<CarModel> cars = const [],
    FuelPriceModel? fuelPrices,
    String? weatherContext,
    List<DailyLogModel> dailyLogs = const [],
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final latestQuestion = history.last.content;

    if (apiKey.trim().isEmpty) {
      return _fallbackAnswer(latestQuestion, trips, cars, fuelPrices, weatherContext, dailyLogs);
    }

    final tripContext = _buildTripContext(trips);
    final carContext = _buildCarContext(cars);
    final fuelContext = _buildFuelContext(fuelPrices);
    final weatherText = _buildWeatherContext(weatherContext);
    final dailyLogContext = _buildDailyLogContext(dailyLogs);

    final systemPrompt = '''
Bạn là Trợ lý ảo Du Lịch Năm Ái, một trợ lý thông minh và thân thiện chuyên giúp chủ xe quản lý đội xe du lịch (7 chỗ và 16 chỗ) chạy hợp đồng của nhà xe Năm Ái.

Nhiệm vụ:
- Tư vấn về lịch đặt xe, doanh số và sắp xếp xe rảnh bận.
- Nhắc nhở danh sách chuyến đi của ngày hôm nay hoặc sắp tới khi được hỏi. Gợi ý chuyến đón khách nào trước dựa vào giờ đón, loại xe cần chuẩn bị.
- Tính toán doanh số dự kiến hoặc phân tích các thông số tài chính khi chủ xe hỏi về doanh thu hoặc báo cáo tiền cọc/còn lại.
- Nếu được hỏi "Hôm nay chạy xe nào?" hoặc "Lịch chạy xe hôm nay": Hãy đối chiếu trạng thái xe và danh sách chuyến đi trong ngày hôm nay để khuyên tài xế/chủ xe chuẩn bị. Nhắc nhở đón đúng giờ.
- Nếu được hỏi về giá xăng dầu hay chi phí chạy xe: Tư vấn dựa trên thông số giá xăng dầu hiện tại được cấu hình bên dưới và đưa ra nhận xét về công thức tính giá đề xuất.
- Trả lời ngắn gọn, có cấu trúc bullet point rõ ràng bằng tiếng Việt, ấm áp và chuyên nghiệp. Tuyệt đối không tự bịa đặt chuyến xe hoặc thông số nếu dữ liệu truyền vào không có.

$weatherText

$fuelContext

$carContext

$tripContext

$dailyLogContext
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

      final text = response.data['choices'][0]['message']['content']?.toString();

      if (text == null || text.trim().isEmpty) {
        return _fallbackAnswer(latestQuestion, trips, cars, fuelPrices, weatherContext, dailyLogs);
      }

      return text.trim();
    } on DioException catch (e) {
      print('=== GROQ ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Body: ${e.response?.data}');
      return _fallbackAnswer(latestQuestion, trips, cars, fuelPrices, weatherContext, dailyLogs);
    } catch (e) {
      print('=== UNKNOWN ERROR: $e ===');
      return _fallbackAnswer(latestQuestion, trips, cars, fuelPrices, weatherContext, dailyLogs);
    }
  }

  String _buildWeatherContext(String? weatherContext) {
    if (weatherContext == null || weatherContext.trim().isEmpty) {
      return '=== THỜI TIẾT HIỆN TẠI ===\nChưa có thông tin thời tiết.';
    }
    return '=== THỜI TIẾT HIỆN TẠI ===\n${weatherContext.trim()}';
  }

  String _buildFuelContext(FuelPriceModel? fuelPrices) {
    if (fuelPrices == null) {
      return '=== BẢNG GIÁ NHIÊN LIỆU ===\nChưa cập nhật giá nhiên liệu.';
    }
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return '''
=== BẢNG GIÁ NHIÊN LIỆU (MỚI NHẤT) ===
- Xăng RON95: ${fuelPrices.ron95.toStringAsFixed(0)} VND/lít
- Xăng E5 RON92: ${fuelPrices.e5Ron92.toStringAsFixed(0)} VND/lít
- Dầu Diesel: ${fuelPrices.diesel.toStringAsFixed(0)} VND/lít
- Nguồn: ${fuelPrices.source}
- Cập nhật lúc: ${fmt.format(fuelPrices.updatedAt)}
''';
  }

  String _buildDailyLogContext(List<DailyLogModel> dailyLogs) {
    if (dailyLogs.isEmpty) {
      return '=== NHẬT KÝ TUYẾN HÀNG NGÀY ===\nChưa có nhật ký ghi nhận chạy tuyến hàng ngày.';
    }
    final buffer = StringBuffer();
    buffer.writeln('=== NHẬT KÝ CHẠY TUYẾN HÀNG NGÀY & TÀI CHÍNH THỰC TẾ ===');
    buffer.writeln('Lưu ý nghiệp vụ: Vé xe 16 chỗ chạy tuyến hàng ngày là 90k/khách. Mỗi ngày chạy 2 vòng gồm 4 lượt: Sáng Vào, Sáng Ra, Chiều Vào, Chiều Ra.');
    buffer.writeln('Khi xe 16 chỗ đi tour, xe 7 chỗ sẽ tự động chạy thay thế tuyến hàng ngày này.');
    for (final log in dailyLogs.take(20)) {
      final dateStr = DateFormat('dd/MM/yyyy').format(log.date);
      buffer.writeln('- Ngày $dateStr:');
      buffer.writeln('  • Lượt khách: Sáng Vào (${log.passengerCountMorningIn}), Sáng Ra (${log.passengerCountMorningOut}), Chiều Vào (${log.passengerCountAfternoonIn}), Chiều Ra (${log.passengerCountAfternoonOut}). Tổng: ${log.totalPassengers} khách.');
      buffer.writeln('  • Doanh thu chạy tuyến: ${log.routeRevenue.toStringAsFixed(0)}đ');
      buffer.writeln('  • Vốn bỏ ra hôm đó: ${log.capital.toStringAsFixed(0)}đ');
      buffer.writeln('  • Tiền dầu đổ thực tế: ${log.actualFuelCost.toStringAsFixed(0)}đ');
    }
    return buffer.toString();
  }

  String _buildCarContext(List<CarModel> cars) {
    if (cars.isEmpty) {
      return '=== DANH SÁCH XE ===\nChưa có xe nào được khai báo.';
    }
    final buffer = StringBuffer();
    buffer.writeln('=== DANH SÁCH XE TRONG HỆ THỐNG ===');
    for (final c in cars) {
      final typeText = c.carType == '7_seater' ? '7 chỗ' : '16 chỗ';
      final fuelText = c.fuelType == 'ron95' ? 'Xăng RON95' : (c.fuelType == 'diesel' ? 'Dầu Diesel' : 'Xăng E5');
      final statusText = c.status == 'free' ? 'RẢNH' : (c.status == 'busy' ? 'ĐANG CHẠY' : 'BẢO TRÌ');
      buffer.writeln('- Xe: ${c.name} (BKS: ${c.plateNumber}) | Loại: $typeText | Nhiên liệu: $fuelText (Định mức: ${c.fuelConsumptionPer100Km}L/100km) | Trạng thái: $statusText');
    }
    return buffer.toString();
  }

  String _buildTripContext(List<TripModel> trips) {
    if (trips.isEmpty) {
      return '=== DANH SÁCH ĐẶT XE ===\nChưa có lịch đặt xe nào.';
    }
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();
    buffer.writeln('=== DANH SÁCH ĐẶT XE (TRIPS) ===');
    buffer.writeln('Thời điểm hiện tại: ${fmt.format(now)}');
    buffer.writeln('Tổng số chuyến: ${trips.length}');
    buffer.writeln();

    for (final t in trips) {
      final statusText = _getVietnameseStatus(t.status);
      final carLabel = t.carType == '7_seater' ? 'Xe 7 chỗ' : 'Xe 16 chỗ';
      buffer.writeln('- Chuyến đi đón khách: **${t.customerName}** (SĐT: ${t.customerPhone})');
      buffer.writeln('  Giờ đón: ${fmt.format(t.startTime)}');
      buffer.writeln('  Lộ trình: Từ ${t.pickupLocation} đi ${t.destination} (${t.estimatedKm} km)');
      buffer.writeln('  Phương tiện: $carLabel (Mã xe: ${t.carId})');
      buffer.writeln('  Tài chính: Giá đề xuất: ${t.suggestedPrice.toStringAsFixed(0)}đ | Giá chốt: ${t.finalPrice.toStringAsFixed(0)}đ | Đã cọc: ${t.deposit.toStringAsFixed(0)}đ | Còn lại: ${t.remainingAmount.toStringAsFixed(0)}đ');
      buffer.writeln('  Trạng thái: $statusText');
      if (t.note.trim().isNotEmpty) {
        buffer.writeln('  Ghi chú: ${t.note}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _getVietnameseStatus(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'running': return 'Đang chạy';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return 'Không xác định';
    }
  }

  String _fallbackAnswer(
    String question,
    List<TripModel> trips,
    List<CarModel> cars,
    FuelPriceModel? fuelPrices,
    String? weatherContext,
    List<DailyLogModel> dailyLogs,
  ) {
    final lower = question.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Hỏi về giá nhiên liệu
    if (lower.contains('nhiên liệu') || lower.contains('giá xăng') || lower.contains('giá dầu') || lower.contains('xăng dầu')) {
      if (fuelPrices == null) {
        return 'Chưa có thông tin giá nhiên liệu được cấu hình trong hệ thống ngoại tuyến.';
      }
      return 'Báo giá xăng dầu hiện tại (Chế độ offline):\n'
          '- Xăng RON95: ${fuelPrices.ron95.toStringAsFixed(0)}đ/lít\n'
          '- Xăng E5 RON92: ${fuelPrices.e5Ron92.toStringAsFixed(0)}đ/lít\n'
          '- Dầu Diesel: ${fuelPrices.diesel.toStringAsFixed(0)}đ/lít\n'
          '- Cập nhật từ nguồn: ${fuelPrices.source}';
    }

    // 2. Hỏi về tình trạng xe rảnh bận
    if (lower.contains('xe rảnh') || lower.contains('xe trống') || lower.contains('tình trạng xe') || lower.contains('danh sách xe')) {
      if (cars.isEmpty) {
        return 'Không tìm thấy xe nào trong bộ nhớ offline.';
      }
      final buffer = StringBuffer();
      buffer.writeln('Tình trạng xe hiện tại (Chế độ offline):');
      for (final c in cars) {
        final typeText = c.carType == '7_seater' ? '7 chỗ' : '16 chỗ';
        final statusText = c.status == 'free' ? '🟢 RẢNH' : (c.status == 'busy' ? '🔴 ĐANG CHẠY' : '🟡 BẢO TRÌ');
        buffer.writeln('- **${c.name}** (${c.plateNumber}, loại $typeText): $statusText');
      }
      return buffer.toString();
    }

    // 3. Hỏi về kế hoạch chạy xe hôm nay
    if (lower.contains('hôm nay') || lower.contains('lịch') || lower.contains('kế hoạch')) {
      final todayTrips = trips.where((t) {
        return t.startTime.year == now.year &&
            t.startTime.month == now.month &&
            t.startTime.day == now.day;
      }).toList();

      if (todayTrips.isEmpty) {
        return 'Lịch chạy hôm nay: Nhà xe Năm Ái chưa có chuyến xe nào được đặt chạy trong ngày hôm nay! Bạn có thể thêm chuyến mới trên màn hình. 🎉';
      }

      final buffer = StringBuffer();
      buffer.writeln('Lịch trình chạy xe hôm nay (${DateFormat('dd/MM/yyyy').format(now)}):');
      buffer.writeln('Tổng cộng có ${todayTrips.length} chuyến xe.');
      for (final t in todayTrips) {
        final statusText = _getVietnameseStatus(t.status);
        final carType = t.carType == '7_seater' ? '7 chỗ' : '16 chỗ';
        buffer.writeln('- **${t.customerName}** (${t.customerPhone}) đi ${t.destination}:');
        buffer.writeln('  • Giờ đón: ${DateFormat('HH:mm').format(t.startTime)} | Lộ trình: ${t.pickupLocation} -> ${t.destination}');
        buffer.writeln('  • Xe: ${carType} | Trạng thái chuyến: $statusText');
      }
      return buffer.toString();
    }

    // 4. Báo cáo doanh số tài chính
    if (lower.contains('doanh thu') || lower.contains('doanh số') || lower.contains('tiền') || lower.contains('tài chính')) {
      double totalSuggested = 0;
      double totalFinal = 0;
      double totalDeposit = 0;
      double totalRemaining = 0;

      for (final t in trips) {
        if (t.status != 'cancelled') {
          totalSuggested += t.suggestedPrice;
          totalFinal += t.finalPrice;
          totalDeposit += t.deposit;
          totalRemaining += t.remainingAmount;
        }
      }

      return 'Báo cáo doanh thu nhà xe Năm Ái (Tính trên các chuyến chưa hủy):\n'
          '- Tổng giá trị đề xuất: ${totalSuggested.toStringAsFixed(0)}đ\n'
          '- Tổng giá trị chốt: **${totalFinal.toStringAsFixed(0)}đ**\n'
          '- Tổng tiền cọc đã thu: ${totalDeposit.toStringAsFixed(0)}đ\n'
          '- Tổng tiền còn lại cần thu: **${totalRemaining.toStringAsFixed(0)}đ**';
    }

    // 5. Hỏi về chạy tuyến xe 16 chỗ cố định hàng ngày
    if (lower.contains('chạy tuyến') || lower.contains('tuyến cố định') || lower.contains('tuyến hàng ngày') || lower.contains('vòng') || lower.contains('khách chạy')) {
      if (dailyLogs.isEmpty) {
        return 'Nhật ký chạy tuyến hàng ngày đang trống. Hãy nhập số lượng khách chạy hàng ngày của bạn trên Dashboard!';
      }
      final buffer = StringBuffer();
      buffer.writeln('Báo cáo chạy tuyến hàng ngày xe 16 chỗ (Vé 90.000đ/khách):');
      double totalRouteRev = 0;
      double totalCapital = 0;
      double totalActualFuel = 0;
      for (final log in dailyLogs.take(5)) {
        final dateStr = DateFormat('dd/MM/yyyy').format(log.date);
        buffer.writeln('- Ngày $dateStr: ${log.totalPassengers} khách | Sáng: ${log.passengerCountMorningIn} vào / ${log.passengerCountMorningOut} ra | Chiều: ${log.passengerCountAfternoonIn} vào / ${log.passengerCountAfternoonOut} ra.');
        buffer.writeln('  • Doanh thu: ${log.routeRevenue.toStringAsFixed(0)}đ | Dầu đổ: ${log.actualFuelCost.toStringAsFixed(0)}đ | Vốn: ${log.capital.toStringAsFixed(0)}đ');
        totalRouteRev += log.routeRevenue;
        totalCapital += log.capital;
        totalActualFuel += log.actualFuelCost;
      }
      buffer.writeln('Tổng quan 5 ngày ghi nhận gần nhất:');
      buffer.writeln('  • Tổng doanh thu chạy tuyến: ${totalRouteRev.toStringAsFixed(0)}đ');
      buffer.writeln('  • Tổng tiền dầu đã đổ: ${totalActualFuel.toStringAsFixed(0)}đ');
      buffer.writeln('  • Tổng vốn đã bỏ ra: ${totalCapital.toStringAsFixed(0)}đ');
      return buffer.toString();
    }

    return 'Trợ lý Du Lịch Năm Ái xin chào! Tôi đang chạy ở chế độ offline. Bạn có thể hỏi tôi về:\n'
        '- Giá xăng dầu hiện tại\n'
        '- Tình trạng rảnh bận của đội xe\n'
        '- Lịch trình chạy xe ngày hôm nay\n'
        '- Báo cáo doanh thu của nhà xe';
  }
}