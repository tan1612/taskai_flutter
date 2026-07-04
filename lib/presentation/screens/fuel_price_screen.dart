import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskai/presentation/providers/fuel_provider.dart';

class FuelPriceScreen extends ConsumerStatefulWidget {
  const FuelPriceScreen({super.key});

  @override
  ConsumerState<FuelPriceScreen> createState() => _FuelPriceScreenState();
}

class _FuelPriceScreenState extends ConsumerState<FuelPriceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ron95Controller;
  late TextEditingController _e5Controller;
  late TextEditingController _dieselController;
  late TextEditingController _sourceController;

  @override
  void initState() {
    super.initState();
    final currentPrices = ref.read(fuelPriceProvider);
    _ron95Controller = TextEditingController(text: currentPrices.ron95.toStringAsFixed(0));
    _e5Controller = TextEditingController(text: currentPrices.e5Ron92.toStringAsFixed(0));
    _dieselController = TextEditingController(text: currentPrices.diesel.toStringAsFixed(0));
    _sourceController = TextEditingController(text: currentPrices.source);
  }

  @override
  void dispose() {
    _ron95Controller.dispose();
    _e5Controller.dispose();
    _dieselController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final double ron95 = double.parse(_ron95Controller.text);
    final double e5 = double.parse(_e5Controller.text);
    final double diesel = double.parse(_dieselController.text);
    final String source = _sourceController.text.trim();

    ref.read(fuelPriceProvider.notifier).updatePrices(
      ron95: ron95,
      e5Ron92: e5,
      diesel: diesel,
      source: source,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật bảng giá xăng dầu thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prices = ref.watch(fuelPriceProvider);
    final scheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ/Lít', decimalDigits: 0);
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bảng Giá Nhiên Liệu',
          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thẻ tóm tắt giá hiện tại
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
                      children: [
                        Icon(Icons.local_gas_station_rounded, color: scheme.primary, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Giá nhiên liệu Petrolimex áp dụng',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildPriceRow('Xăng Cao Cấp RON95-III', prices.ron95, currencyFormat, Colors.orange, scheme),
                    _buildPriceRow('Xăng Sinh Học E5 RON92', prices.e5Ron92, currencyFormat, Colors.redAccent, scheme),
                    _buildPriceRow('Dầu Diesel 0.05S-II', prices.diesel, currencyFormat, Colors.blue, scheme),
                    const Divider(height: 24),
                    Text(
                      'Nguồn cập nhật: ${prices.source}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Cập nhật lúc: ${timeFormat.format(prices.updatedAt.toLocal())}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form cập nhật giá thủ công
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cập nhật thủ công bảng giá xăng dầu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ron95Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá xăng RON 95 (đ/Lít) *',
                prefixIcon: Icon(Icons.gas_meter_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || double.tryParse(v) == null ? 'Vui lòng nhập giá RON95 hợp lệ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _e5Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá xăng E5 RON 92 (đ/Lít) *',
                prefixIcon: Icon(Icons.gas_meter_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || double.tryParse(v) == null ? 'Vui lòng nhập giá E5 RON92 hợp lệ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dieselController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá dầu Diesel (đ/Lít) *',
                prefixIcon: Icon(Icons.gas_meter_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || double.tryParse(v) == null ? 'Vui lòng nhập giá dầu Diesel hợp lệ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Nguồn giá cập nhật (ví dụ: Petrolimex) *',
                prefixIcon: Icon(Icons.source_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập nguồn thông tin giá' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu bảng giá nhiên liệu', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String fuelName,
    double price,
    NumberFormat format,
    Color fuelColor,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: fuelColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                fuelName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Text(
            format.format(price),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
