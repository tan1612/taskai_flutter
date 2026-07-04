import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/data/models/weather_model.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/providers/trip_provider.dart';
import 'package:taskai/presentation/providers/car_provider.dart';
import 'package:taskai/presentation/providers/weather_provider.dart';
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
