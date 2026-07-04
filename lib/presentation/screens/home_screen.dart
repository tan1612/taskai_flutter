import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/data/models/weather_model.dart';
import 'package:taskai/data/models/daily_log_model.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/providers/trip_provider.dart';
import 'package:taskai/presentation/providers/car_provider.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/screens/trip_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getWeatherRecommendation(WeatherModel weather) {
    final desc = weather.description.toLowerCase();
    final temp = weather.temperature;
    final wind = weather.windSpeed;

    if (desc.contains('mưa') || desc.contains('dông') || desc.contains('phùn')) {
      return 'Trời có mưa/dông. Hãy nhắc nhở tài xế lái xe chậm, kiểm tra lốp và gạt mưa! 🌧️';
    }
    if (temp > 33) {
      return 'Thời tiết nắng nóng gay gắt. Hãy bật điều hòa xe trước khi đón khách! ☀️';
    }
    if (wind > 8) {
      return 'Có gió mạnh ngoài trời. Tài xế cần chú ý vững tay lái khi chạy cao tốc! 💨';
    }
    return 'Thời tiết hôm nay rất tốt, đường xá thuận lợi cho các chuyến đi! 🌟';
  }

  TripModel? _getNextUpcomingTrip(List<TripModel> trips) {
    final now = DateTime.now();
    final upcoming = trips.where((t) => t.status != 'cancelled' && t.status != 'completed' && t.startTime.isAfter(now)).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripProvider);
    final cars = ref.watch(carProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final authState = ref.watch(authNotifierProvider);

    final now = DateTime.now();
    final todayTrips = trips.where((t) =>
        t.startTime.year == now.year &&
        t.startTime.month == now.month &&
        t.startTime.day == now.day &&
        t.status != 'cancelled').toList();

    double expectedRevenueToday = 0;
    for (final t in todayTrips) {
      expectedRevenueToday += t.finalPrice;
    }

    final nextTrip = _getNextUpcomingTrip(trips);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    final userName = authState.user != null
        ? (authState.user!.email!.split('@')[0])
        : 'Chủ Xe';

    final scheme = Theme.of(context).colorScheme;

    // Lấy thông tin trạng thái 2 xe mặc định
    final car7 = cars.firstWhere((c) => c.carType == '7_seater', orElse: () => CarModel(id: '', name: 'Xe 7 chỗ', plateNumber: 'Trống', carType: '7_seater', fuelType: 'ron95', fuelConsumptionPer100Km: 9, status: 'free'));
    final car16 = cars.firstWhere((c) => c.carType == '16_seater', orElse: () => CarModel(id: '', name: 'Xe 16 chỗ', plateNumber: 'Trống', carType: '16_seater', fuelType: 'diesel', fuelConsumptionPer100Km: 11.5, status: 'free'));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Du Lịch Năm Ái',
          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại thời tiết',
            onPressed: () {
              ref.invalidate(weatherProvider);
              ref.invalidate(forecastWeatherProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(forecastWeatherProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner chào mừng và doanh thu dự kiến
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, $userName! 👋',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chào mừng bạn đến với nhà xe Năm Ái',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số chuyến hôm nay',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${todayTrips.length} chuyến',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Doanh thu dự kiến',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(expectedRevenueToday),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tình trạng 2 loại xe (7 chỗ và 16 chỗ)
            Text(
              'Tình trạng đội xe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CarStatusCard(
                    title: 'Xe 7 Chỗ',
                    name: car7.name,
                    plate: car7.plateNumber,
                    status: car7.status,
                    icon: Icons.directions_car_filled_rounded,
                    colorScheme: scheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CarStatusCard(
                    title: 'Xe 16 Chỗ',
                    name: car16.name,
                    plate: car16.plateNumber,
                    status: car16.status,
                    icon: Icons.airport_shuttle_rounded,
                    colorScheme: scheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const DailyRoutePanel(),
            const SizedBox(height: 20),

            // Chuyến đi tiếp theo
            Text(
              'Chuyến đi sắp tới tiếp theo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (nextTrip != null)
              _NextTripCard(trip: nextTrip, currencyFormat: currencyFormat, colorScheme: scheme)
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Hiện tại chưa có chuyến đi nào được đặt tiếp theo.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Thời tiết hiện tại tại khu vực nhà xe
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời tiết & Lộ trình di chuyển',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    weatherAsync.when(
                      data: (weather) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weather.cityName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  Text(
                                    weather.description.toUpperCase(),
                                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Text(
                                '${weather.temperature.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tips_and_updates_rounded, color: scheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getWeatherRecommendation(weather),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const Text('Không có dữ liệu thời tiết. Hãy cắm mạng để cập nhật.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Chừa khoảng trống cho FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_create_trip',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripFormScreen()),
        ),
        icon: const Icon(Icons.add_road_rounded),
        label: const Text('Thêm chuyến mới'),
      ),
    );
  }
}

class _CarStatusCard extends StatelessWidget {
  final String title;
  final String name;
  final String plate;
  final String status;
  final IconData icon;
  final ColorScheme colorScheme;

  const _CarStatusCard({
    required this.title,
    required this.name,
    required this.plate,
    required this.status,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (status == 'free') {
      statusColor = Colors.green;
      statusText = 'Rảnh';
    } else if (status == 'busy') {
      statusColor = Colors.red;
      statusText = 'Bận chạy';
    } else {
      statusColor = Colors.amber;
      statusText = 'Bảo trì';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              plate,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextTripCard extends StatelessWidget {
  final TripModel trip;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _NextTripCard({
    required this.trip,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(trip.startTime);
    final carLabel = trip.carType == '7_seater' ? 'Xe 7 chỗ' : 'Xe 16 chỗ';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    carLabel,
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.person_pin_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Khách hàng: ${trip.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lộ trình: ${trip.pickupLocation} ➔ ${trip.destination}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giá chốt: ${currencyFormat.format(trip.finalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.redAccent),
                ),
                Text(
                  'Đặt cọc: ${currencyFormat.format(trip.deposit)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DailyRoutePanel extends ConsumerStatefulWidget {
  const DailyRoutePanel({super.key});

  @override
  ConsumerState<DailyRoutePanel> createState() => _DailyRoutePanelState();
}

class _DailyRoutePanelState extends ConsumerState<DailyRoutePanel> {
  DateTime _selectedDate = DateTime.now();
  final _capitalController = TextEditingController();
  final _fuelController = TextEditingController();

  int _morningIn = 0;
  int _morningOut = 0;
  int _afternoonIn = 0;
  int _afternoonOut = 0;

  DailyLogModel? _lastLoadedLog;
  DateTime? _lastLoadedDate;

  @override
  void dispose() {
    _capitalController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  void _syncStateWithLog(DailyLogModel? log, DateTime date) {
    if (_lastLoadedDate == date && _lastLoadedLog == log) return;
    _lastLoadedDate = date;
    _lastLoadedLog = log;

    if (log != null) {
      _morningIn = log.passengerCountMorningIn;
      _morningOut = log.passengerCountMorningOut;
      _afternoonIn = log.passengerCountAfternoonIn;
      _afternoonOut = log.passengerCountAfternoonOut;
      _capitalController.text = log.capital.toStringAsFixed(0);
      _fuelController.text = log.actualFuelCost.toStringAsFixed(0);
    } else {
      _morningIn = 0;
      _morningOut = 0;
      _afternoonIn = 0;
      _afternoonOut = 0;
      _capitalController.text = '0';
      _fuelController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyLogs = ref.watch(dailyLogProvider);
    final trips = ref.watch(tripProvider);
    final scheme = Theme.of(context).colorScheme;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    DailyLogModel? currentLog;
    try {
      currentLog = dailyLogs.firstWhere((l) => l.id == dateStr);
    } catch (_) {
      currentLog = null;
    }

    _syncStateWithLog(currentLog, _selectedDate);

    // Kiểm tra xe 16 chỗ chạy tour hôm nay
    final is16SeaterOnTour = trips.any((t) =>
        t.carType == '16_seater' &&
        t.status != 'cancelled' &&
        t.startTime.year == _selectedDate.year &&
        t.startTime.month == _selectedDate.month &&
        t.startTime.day == _selectedDate.day);

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    // Tính toán tài chính hôm nay
    final double routeRevToday = (_morningIn + _morningOut + _afternoonIn + _afternoonOut) * 90000.0;
    final today16SeaterTrips = trips.where((t) =>
        t.carType == '16_seater' &&
        t.status != 'cancelled' &&
        t.startTime.year == _selectedDate.year &&
        t.startTime.month == _selectedDate.month &&
        t.startTime.day == _selectedDate.day).toList();
    final double tourRevToday = today16SeaterTrips.fold(0.0, (sum, t) => sum + t.finalPrice);
    final double tourCostToday = today16SeaterTrips.fold(0.0, (sum, t) => sum + t.tollFee + t.driverFee + t.otherFee);
    final double fuelToday = double.tryParse(_fuelController.text) ?? 0.0;
    final double capitalToday = double.tryParse(_capitalController.text) ?? 0.0;
    final double profitToday = (routeRevToday + tourRevToday) - fuelToday - tourCostToday - capitalToday;

    // Tính toán tài chính tháng này
    final monthLogs = dailyLogs.where((l) => l.date.year == _selectedDate.year && l.date.month == _selectedDate.month).toList();
    final monthTrips = trips.where((t) =>
        t.carType == '16_seater' &&
        t.status != 'cancelled' &&
        t.startTime.year == _selectedDate.year &&
        t.startTime.month == _selectedDate.month).toList();
    final double routeRevMonth = monthLogs.fold(0.0, (sum, l) => sum + l.routeRevenue);
    final double tourRevMonth = monthTrips.fold(0.0, (sum, t) => sum + t.finalPrice);
    final double fuelMonth = monthLogs.fold(0.0, (sum, l) => sum + l.actualFuelCost);
    final double capitalMonth = monthLogs.fold(0.0, (sum, l) => sum + l.capital);
    final double tourCostMonth = monthTrips.fold(0.0, (sum, t) => sum + t.tollFee + t.driverFee + t.otherFee);
    final double profitMonth = (routeRevMonth + tourRevMonth) - fuelMonth - tourCostMonth - capitalMonth;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ngày & chọn ngày
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tuyến 16 chỗ & Tài chính',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Warning chạy thay thế
            if (is16SeaterOnTour) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.airport_shuttle_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hôm nay xe 16 chỗ bận chạy Tour. Xe 7 chỗ tự động chạy thay thế tuyến hàng ngày.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4 lượt chạy tuyến hàng ngày (90k/khách)
            const Text(
              'Số lượng khách đi hôm nay (90k/khách):',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCounterItem('Sáng - Vào', _morningIn, (val) => setState(() => _morningIn = val), scheme),
                _buildCounterItem('Sáng - Ra', _morningOut, (val) => setState(() => _morningOut = val), scheme),
                _buildCounterItem('Chiều - Vào', _afternoonIn, (val) => setState(() => _afternoonIn = val), scheme),
                _buildCounterItem('Chiều - Ra', _afternoonOut, (val) => setState(() => _afternoonOut = val), scheme),
              ],
            ),
            const Divider(height: 32),

            // Nhập Vốn & Tiền dầu đổ thực tế
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capitalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Vốn bỏ ra hôm nay',
                      suffixText: 'đ',
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _fuelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tiền dầu đổ hôm nay',
                      suffixText: 'đ',
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nút lưu nhật ký ngày
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final capital = double.tryParse(_capitalController.text) ?? 0.0;
                  final fuel = double.tryParse(_fuelController.text) ?? 0.0;
                  await ref.read(dailyLogProvider.notifier).saveDailyLog(
                        dateStr: dateStr,
                        morningIn: _morningIn,
                        morningOut: _morningOut,
                        afternoonIn: _afternoonIn,
                        afternoonOut: _afternoonOut,
                        capital: capital,
                        actualFuelCost: fuel,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã lưu nhật ký ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)} thành công!')),
                    );
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('LƯU NHẬT KÝ NGÀY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
            const Divider(height: 32),

            // Bảng báo cáo đối soát tài chính xe 16 chỗ
            Text(
              'Bảng Đối Soát Doanh Thu Xe 16 Chỗ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: scheme.primary),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ngày hôm nay
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hôm nay (${DateFormat('dd/MM').format(_selectedDate)})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      _buildReportRow('Tuyến hàng ngày:', currencyFormat.format(routeRevToday), scheme),
                      _buildReportRow('Hợp đồng Tour:', currencyFormat.format(tourRevToday), scheme),
                      _buildReportRow('Dầu thực tế:', '-${currencyFormat.format(fuelToday)}', scheme, valueColor: Colors.redAccent),
                      _buildReportRow('Chi phí Tour:', '-${currencyFormat.format(tourCostToday)}', scheme, valueColor: Colors.redAccent),
                      _buildReportRow('Vốn bỏ ra:', '-${currencyFormat.format(capitalToday)}', scheme, valueColor: Colors.redAccent),
                      const Divider(height: 12),
                      _buildReportRow(
                        'Lợi nhuận ròng:',
                        currencyFormat.format(profitToday),
                        scheme,
                        isBold: true,
                        valueColor: profitToday >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Tháng này
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tháng này (${DateFormat('MM/yy').format(_selectedDate)})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      _buildReportRow('Doanh thu tuyến:', currencyFormat.format(routeRevMonth), scheme),
                      _buildReportRow('Doanh thu Tour:', currencyFormat.format(tourRevMonth), scheme),
                      _buildReportRow('Tổng tiền dầu:', '-${currencyFormat.format(fuelMonth)}', scheme, valueColor: Colors.redAccent),
                      _buildReportRow('Tổng phí Tour:', '-${currencyFormat.format(tourCostMonth)}', scheme, valueColor: Colors.redAccent),
                      _buildReportRow('Tổng vốn:', '-${currencyFormat.format(capitalMonth)}', scheme, valueColor: Colors.redAccent),
                      const Divider(height: 12),
                      _buildReportRow(
                        'Tổng lợi nhuận:',
                        currencyFormat.format(profitMonth),
                        scheme,
                        isBold: true,
                        valueColor: profitMonth >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterItem(String label, int value, ValueChanged<int> onChanged, ColorScheme scheme) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            SizedBox(
              width: 16,
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: () => onChanged(value + 1),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value, ColorScheme scheme, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onSurface.withOpacity(0.8),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
