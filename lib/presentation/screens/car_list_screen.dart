import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/presentation/providers/car_provider.dart';

class CarListScreen extends ConsumerWidget {
  const CarListScreen({super.key});

  void _showEditCarDialog(BuildContext context, WidgetRef ref, CarModel car) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: car.name);
    final plateController = TextEditingController(text: car.plateNumber);
    final consumptionController = TextEditingController(text: car.fuelConsumptionPer100Km.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sửa thông tin: ${car.carType == '7_seater' ? 'Xe 7 chỗ' : 'Xe 16 chỗ'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên dòng xe', prefixIcon: Icon(Icons.car_repair)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên xe' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Biển số xe', prefixIcon: Icon(Icons.credit_card_rounded)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập biển số' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: consumptionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Mức tiêu hao (L/100km)', prefixIcon: Icon(Icons.local_gas_station_rounded)),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Vui lòng nhập định mức tiêu hao hợp lệ' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updated = car.copyWith(
                  name: nameController.text.trim(),
                  plateNumber: plateController.text.trim(),
                  fuelConsumptionPer100Km: double.parse(consumptionController.text),
                );
                ref.read(carProvider.notifier).updateCar(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật thông tin xe thành công!')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản Lý Đội Xe',
          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
        ),
      ),
      body: cars.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                final is7Seater = car.carType == '7_seater';
                final carIcon = is7Seater ? Icons.directions_car_filled_rounded : Icons.airport_shuttle_rounded;
                final typeLabel = is7Seater ? 'Xe 7 chỗ du lịch' : 'Xe 16 chỗ hợp đồng';

                Color statusColor;
                String statusLabel;
                switch (car.status) {
                  case 'free':
                    statusColor = Colors.green;
                    statusLabel = '🟢 Xe đang rảnh';
                    break;
                  case 'busy':
                    statusColor = Colors.red;
                    statusLabel = '🔴 Đang chạy chuyến';
                    break;
                  case 'maintenance':
                    statusColor = Colors.amber;
                    statusLabel = '🟡 Đang bảo trì';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusLabel = 'Không rõ trạng thái';
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
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
                            Row(
                              children: [
                                Icon(carIcon, color: scheme.primary, size: 28),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.name,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    Text(
                                      typeLabel,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton.filledTonal(
                              onPressed: () => _showEditCarDialog(context, ref, car),
                              icon: const Icon(Icons.edit_note_rounded, size: 20),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildCarDetailRow('Biển kiểm soát:', car.plateNumber),
                        _buildCarDetailRow('Loại nhiên liệu:', car.fuelType == 'ron95' ? 'Xăng RON95' : 'Dầu Diesel'),
                        _buildCarDetailRow('Định mức tiêu hao:', '${car.fuelConsumptionPer100Km} L/100km'),
                        _buildCarDetailRow('Trạng thái hiện tại:', statusLabel, valueColor: statusColor),
                        const SizedBox(height: 16),
                        const Text(
                          'Cập nhật nhanh trạng thái xe:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildQuickStatusButton(
                              context, ref, car, 'free', 'Rảnh', Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildQuickStatusButton(
                              context, ref, car, 'busy', 'Bận chạy', Colors.red,
                            ),
                            const SizedBox(width: 8),
                            _buildQuickStatusButton(
                              context, ref, car, 'maintenance', 'Bảo trì', Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCarDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusButton(
    BuildContext context,
    WidgetRef ref,
    CarModel car,
    String statusValue,
    String label,
    Color color,
  ) {
    final isSelected = car.status == statusValue;
    return Expanded(
      child: isSelected
          ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withOpacity(0.8),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            )
          : OutlinedButton(
              onPressed: () {
                final updated = car.copyWith(status: statusValue);
                ref.read(carProvider.notifier).updateCar(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật xe ${car.name} sang trạng thái: $label')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
    );
  }
}
