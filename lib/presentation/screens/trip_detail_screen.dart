import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/presentation/providers/trip_provider.dart';
import 'package:taskai/presentation/screens/trip_form_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _makeCall(String phone, BuildContext context) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng gọi điện.')),
        );
      }
    }
  }

  Future<void> _openMap(String location, BuildContext context) async {
    if (location.trim().isEmpty) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps.')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa chuyến xe này khỏi lịch trình không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(tripProvider.notifier).deleteTrip(tripId);
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(context); // Quay lại màn hình danh sách
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripProvider);
    final scheme = Theme.of(context).colorScheme;
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    // Tìm chuyến xe tương ứng trong state
    final TripModel? trip = trips.any((t) => t.id == tripId) ? trips.firstWhere((t) => t.id == tripId) : null;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyến đi')),
        body: const Center(child: Text('Không tìm thấy chuyến đi này.')),
      );
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chuyến đi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Sửa chuyến xe',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip)),
            ),
          ),
          IconButton(
            tooltip: 'Xóa chuyến xe',
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thẻ tóm tắt chính
          Card(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(
                        carLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: scheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Khách hàng:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(trip.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('SĐT: ${trip.customerPhone}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () => _makeCall(trip.customerPhone, context),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lộ trình chi tiết
          Card(
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
                  Text(
                    'Lộ trình & Bản đồ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationRow(
                    context,
                    title: 'Điểm đón khách (Pickup)',
                    address: trip.pickupLocation,
                    iconColor: Colors.green,
                    icon: Icons.location_on_rounded,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                    child: Icon(Icons.arrow_downward_rounded, color: Colors.grey, size: 16),
                  ),
                  _buildLocationRow(
                    context,
                    title: 'Điểm đến (Destination)',
                    address: trip.destination,
                    iconColor: Colors.redAccent,
                    icon: Icons.flag_rounded,
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số km ước tính:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${trip.estimatedKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tài chính & Báo giá chi tiết
          Card(
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
                  Text(
                    'Chi tiết tài chính',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  _buildFinanceRow('Định mức tiêu hao:', '${trip.fuelConsumptionPer100Km} L/100km'),
                  _buildFinanceRow('Giá xăng dầu áp dụng:', formatCurrency.format(trip.fuelPrice)),
                  _buildFinanceRow('Chi phí nhiên liệu:', formatCurrency.format(trip.fuelCost), isBold: true),
                  _buildFinanceRow('Phí cầu đường:', formatCurrency.format(trip.tollFee)),
                  _buildFinanceRow('Công tài xế:', formatCurrency.format(trip.driverFee)),
                  _buildFinanceRow('Chi phí khác:', formatCurrency.format(trip.otherFee)),
                  _buildFinanceRow('Lợi nhuận dự kiến:', formatCurrency.format(trip.expectedProfit)),
                  const Divider(height: 24),
                  _buildFinanceRow(
                    'Giá đề xuất ban đầu:',
                    formatCurrency.format(trip.suggestedPrice),
                    labelColor: scheme.primary,
                  ),
                  _buildFinanceRow(
                    'Giá chốt với khách:',
                    formatCurrency.format(trip.finalPrice),
                    isBold: true,
                    labelColor: Colors.redAccent,
                    fontSize: 16,
                  ),
                  _buildFinanceRow(
                    'Khách cọc trước:',
                    formatCurrency.format(trip.deposit),
                    labelColor: Colors.green,
                  ),
                  const Divider(height: 24),
                  _buildFinanceRow(
                    'Số tiền còn lại cần thu:',
                    formatCurrency.format(trip.remainingAmount),
                    isBold: true,
                    labelColor: Colors.red,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ghi chú & Cập nhật trạng thái
          if (trip.note.isNotEmpty)
            Card(
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
                    Text(
                      'Ghi chú',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.note,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Nút cập nhật nhanh trạng thái chuyến đi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStatusButton(context, ref, 'pending', 'Hủy chốt cọc (Chờ)', Colors.amber),
              const SizedBox(width: 8),
              _buildQuickStatusButton(context, ref, 'confirmed', 'Xác nhận (Cọc)', Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStatusButton(context, ref, 'running', 'Khởi hành (Đang chạy)', Colors.orange),
              const SizedBox(width: 8),
              _buildQuickStatusButton(context, ref, 'completed', 'Hoàn thành chuyến', Colors.green),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required String title,
    required String address,
    required Color iconColor,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => _openMap(address, context),
          icon: const Icon(Icons.map_rounded, size: 18),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
        ),
      ],
    );
  }

  Widget _buildFinanceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? labelColor,
    double fontSize = 13.5,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: labelColor,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: labelColor,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusButton(
    BuildContext context,
    WidgetRef ref,
    String statusValue,
    String label,
    Color color,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          final trips = ref.read(tripProvider);
          final trip = trips.firstWhere((t) => t.id == tripId);
          final updated = trip.copyWith(status: statusValue, updatedAt: DateTime.now());
          ref.read(tripProvider.notifier).addOrUpdate(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật trạng thái sang: $label')),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
