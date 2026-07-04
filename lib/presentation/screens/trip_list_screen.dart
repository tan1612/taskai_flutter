import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/presentation/providers/trip_provider.dart';
import 'package:taskai/presentation/screens/trip_form_screen.dart';
import 'package:taskai/presentation/screens/trip_detail_screen.dart';

class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  String _selectedCarFilter = 'all'; // 'all', '7_seater', '16_seater'
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'confirmed', 'running', 'completed', 'cancelled'

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(tripProvider);
    final scheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    // Áp dụng bộ lọc
    final filteredTrips = allTrips.where((trip) {
      final matchesCar = _selectedCarFilter == 'all' || trip.carType == _selectedCarFilter;
      final matchesStatus = _selectedStatusFilter == 'all' || trip.status == _selectedStatusFilter;
      return matchesCar && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch Trình Chuyến Xe',
          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'trip_list_create',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripFormScreen()),
        ),
        child: const Icon(Icons.add_road_rounded),
      ),
      body: Column(
        children: [
          // Thanh bộ lọc xe
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả xe',
                  value: 'all',
                  selectedValue: _selectedCarFilter,
                  onSelected: (val) => setState(() => _selectedCarFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Xe 7 chỗ',
                  value: '7_seater',
                  selectedValue: _selectedCarFilter,
                  onSelected: (val) => setState(() => _selectedCarFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Xe 16 chỗ',
                  value: '16_seater',
                  selectedValue: _selectedCarFilter,
                  onSelected: (val) => setState(() => _selectedCarFilter = val),
                  colorScheme: scheme,
                ),
              ],
            ),
          ),
          // Thanh bộ lọc trạng thái chuyến
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả trạng thái',
                  value: 'all',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Chờ xác nhận',
                  value: 'pending',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Đã xác nhận',
                  value: 'confirmed',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Đang chạy',
                  value: 'running',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Hoàn thành',
                  value: 'completed',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Đã hủy',
                  value: 'cancelled',
                  selectedValue: _selectedStatusFilter,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                  colorScheme: scheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredTrips.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy chuyến xe nào phù hợp bộ lọc.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return _TripItemCard(
                        trip: trip,
                        currencyFormat: currencyFormat,
                        colorScheme: scheme,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(tripId: trip.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    required ColorScheme colorScheme,
  }) {
    final isSelected = selectedValue == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.4),
      elevation: 0,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _TripItemCard extends StatelessWidget {
  final TripModel trip;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TripItemCard({
    required this.trip,
    required this.currencyFormat,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(trip.startTime);
    final carLabel = trip.carType == '7_seater' ? 'Xe 7 chỗ' : 'Xe 16 chỗ';

    Color statusColor;
    String statusText;
    switch (trip.status) {
      case 'pending':
        statusColor = Colors.amber;
        statusText = 'Chờ xác nhận';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Đã xác nhận';
        break;
      case 'running':
        statusColor = Colors.orange;
        statusText = 'Đang chạy';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Khách hàng: ${trip.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                'SĐT: ${trip.customerPhone}',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lộ trình: ${trip.pickupLocation} ➔ ${trip.destination}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    carLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      const Text('Chốt: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        currencyFormat.format(trip.finalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
