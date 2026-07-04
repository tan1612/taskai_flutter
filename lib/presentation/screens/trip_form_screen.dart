import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/presentation/providers/trip_provider.dart';
import 'package:taskai/presentation/providers/car_provider.dart';
import 'package:taskai/presentation/providers/fuel_provider.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final TripModel? trip; // Nếu truyền vào là chỉnh sửa chuyến xe

  const TripFormScreen({super.key, this.trip});

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _kmController;
  late TextEditingController _consumptionController;
  late TextEditingController _fuelPriceController;
  late TextEditingController _tollController;
  late TextEditingController _driverController;
  late TextEditingController _otherController;
  late TextEditingController _profitController;
  late TextEditingController _finalPriceController;
  late TextEditingController _depositController;
  late TextEditingController _noteController;

  CarModel? _selectedCar;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  String _status = 'pending';

  double _fuelCost = 0.0;
  double _suggestedPrice = 0.0;
  double _remainingAmount = 0.0;

  bool _isEditMode = false;
  bool _isPriceLocked = false; // Khóa giá chốt nếu trạng thái Đã xác nhận / Đang chạy / Hoàn thành

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.trip != null;

    final trip = widget.trip;
    _nameController = TextEditingController(text: trip?.customerName ?? '');
    _phoneController = TextEditingController(text: trip?.customerPhone ?? '');
    _pickupController = TextEditingController(text: trip?.pickupLocation ?? '');
    _destinationController = TextEditingController(text: trip?.destination ?? '');
    _kmController = TextEditingController(text: trip != null ? trip.estimatedKm.toStringAsFixed(0) : '100');
    _consumptionController = TextEditingController(text: trip != null ? trip.fuelConsumptionPer100Km.toString() : '9.0');
    _fuelPriceController = TextEditingController(text: trip != null ? trip.fuelPrice.toStringAsFixed(0) : '23210');
    _tollController = TextEditingController(text: trip != null ? trip.tollFee.toStringAsFixed(0) : '100000');
    _driverController = TextEditingController(text: trip != null ? trip.driverFee.toStringAsFixed(0) : '300000');
    _otherController = TextEditingController(text: trip != null ? trip.otherFee.toStringAsFixed(0) : '50000');
    _profitController = TextEditingController(text: trip != null ? trip.expectedProfit.toStringAsFixed(0) : '300000');
    _finalPriceController = TextEditingController(text: trip != null ? trip.finalPrice.toStringAsFixed(0) : '0');
    _depositController = TextEditingController(text: trip != null ? trip.deposit.toStringAsFixed(0) : '0');
    _noteController = TextEditingController(text: trip?.note ?? '');

    if (trip != null) {
      _selectedDateTime = trip.startTime;
      _status = trip.status;
      if (_status == 'confirmed' || _status == 'running' || _status == 'completed') {
        _isPriceLocked = true;
      }
    }

    // Lắng nghe thay đổi của các ô nhập để tự động tính toán
    _kmController.addListener(_calculateAll);
    _consumptionController.addListener(_calculateAll);
    _fuelPriceController.addListener(_calculateAll);
    _tollController.addListener(_calculateAll);
    _driverController.addListener(_calculateAll);
    _otherController.addListener(_calculateAll);
    _profitController.addListener(_calculateAll);
    _finalPriceController.addListener(_calculateAll);
    _depositController.addListener(_calculateAll);

    // Trì hoãn việc gán xe mặc định để Riverpod đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cars = ref.read(carProvider);
      if (cars.isNotEmpty) {
        setState(() {
          if (_isEditMode) {
            _selectedCar = cars.firstWhere((c) => c.id == widget.trip!.carId, orElse: () => cars.first);
          } else {
            _selectedCar = cars.first; // Mặc định chọn xe 7 chỗ
          }
          _onCarSelected(_selectedCar!);
        });
      }
    });
  }

  void _onCarSelected(CarModel car) {
    if (_isEditMode && car.id == widget.trip!.carId) {
      // Giữ nguyên giá trị khi edit nếu là xe ban đầu
      return;
    }
    final fuelService = ref.read(fuelPriceProvider.notifier).getService();
    final fuelPrice = fuelService.getFuelPriceForType(car.fuelType);

    setState(() {
      _consumptionController.text = car.fuelConsumptionPer100Km.toString();
      _fuelPriceController.text = fuelPrice.toStringAsFixed(0);
      _calculateAll();
    });
  }

  void _calculateAll() {
    final double km = double.tryParse(_kmController.text) ?? 0.0;
    final double consumption = double.tryParse(_consumptionController.text) ?? 0.0;
    final double fuelPrice = double.tryParse(_fuelPriceController.text) ?? 0.0;
    final double toll = double.tryParse(_tollController.text) ?? 0.0;
    final double driver = double.tryParse(_driverController.text) ?? 0.0;
    final double other = double.tryParse(_otherController.text) ?? 0.0;
    final double profit = double.tryParse(_profitController.text) ?? 0.0;
    final double deposit = double.tryParse(_depositController.text) ?? 0.0;

    // Chi phí nhiên liệu = km * mức tiêu hao / 100 * giá nhiên liệu
    final double fuelCost = km * consumption / 100 * fuelPrice;

    // Giá đề xuất = chi phí nhiên liệu + phí cầu đường + công tài xế + chi phí khác + lợi nhuận mong muốn
    final double suggestedPrice = fuelCost + toll + driver + other + profit;

    double finalPrice = double.tryParse(_finalPriceController.text) ?? 0.0;

    // Nếu không bị khóa giá chốt và (là chuyến mới hoặc giá chốt bằng 0), tự động điền giá đề xuất
    if (!_isPriceLocked && (!_isEditMode || widget.trip!.finalPrice == 0 || _status == 'pending')) {
      finalPrice = suggestedPrice;
      _finalPriceController.removeListener(_calculateAll);
      _finalPriceController.text = finalPrice.toStringAsFixed(0);
      _finalPriceController.addListener(_calculateAll);
    }

    // Còn lại = giá chốt - tiền cọc
    final double remaining = finalPrice - deposit;

    setState(() {
      _fuelCost = fuelCost;
      _suggestedPrice = suggestedPrice;
      _remainingAmount = remaining;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _kmController.dispose();
    _consumptionController.dispose();
    _fuelPriceController.dispose();
    _tollController.dispose();
    _driverController.dispose();
    _otherController.dispose();
    _profitController.dispose();
    _finalPriceController.dispose();
    _depositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedCar == null) return;

    final double km = double.tryParse(_kmController.text) ?? 0.0;
    final double consumption = double.tryParse(_consumptionController.text) ?? 0.0;
    final double fuelPrice = double.tryParse(_fuelPriceController.text) ?? 0.0;
    final double toll = double.tryParse(_tollController.text) ?? 0.0;
    final double driver = double.tryParse(_driverController.text) ?? 0.0;
    final double other = double.tryParse(_otherController.text) ?? 0.0;
    final double profit = double.tryParse(_profitController.text) ?? 0.0;
    final double finalPrice = double.tryParse(_finalPriceController.text) ?? 0.0;
    final double deposit = double.tryParse(_depositController.text) ?? 0.0;

    final trip = TripModel(
      id: widget.trip?.id ?? const Uuid().v4(),
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      carId: _selectedCar!.id,
      carType: _selectedCar!.carType,
      fuelType: _selectedCar!.fuelType,
      startTime: _selectedDateTime,
      pickupLocation: _pickupController.text.trim(),
      destination: _destinationController.text.trim(),
      estimatedKm: km,
      fuelConsumptionPer100Km: consumption,
      fuelPrice: fuelPrice,
      fuelCost: _fuelCost,
      tollFee: toll,
      driverFee: driver,
      otherFee: other,
      expectedProfit: profit,
      suggestedPrice: _suggestedPrice,
      finalPrice: finalPrice,
      deposit: deposit,
      remainingAmount: _remainingAmount,
      status: _status,
      note: _noteController.text.trim(),
      createdAt: widget.trip?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(tripProvider.notifier).addOrUpdate(trip);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditMode ? 'Cập nhật chuyến xe thành công!' : 'Thêm chuyến xe thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carProvider);
    final scheme = Theme.of(context).colorScheme;
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa Chuyến Xe' : 'Thêm Chuyến Xe Mới', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin khách hàng
            _buildSectionHeader('Thông tin khách hàng', scheme),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Tên khách hàng *', Icons.person_outline_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên khách hàng' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Số điện thoại *', Icons.phone_android_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
            ),
            const SizedBox(height: 20),

            // Lộ trình chuyến xe
            _buildSectionHeader('Lộ trình & Xe', scheme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: Icon(Icons.calendar_today_rounded, color: scheme.primary),
                    label: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CarModel>(
              value: _selectedCar,
              decoration: _inputDecoration('Chọn xe vận hành *', Icons.directions_car_filled_rounded),
              items: cars.map((car) {
                final carLabel = car.carType == '7_seater' ? 'Xe 7 chỗ' : 'Xe 16 chỗ';
                return DropdownMenuItem<CarModel>(
                  value: car,
                  child: Text('${car.name} (${car.plateNumber}) - $carLabel'),
                );
              }).toList(),
              onChanged: (car) {
                if (car != null) {
                  setState(() {
                    _selectedCar = car;
                    _onCarSelected(car);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupController,
              decoration: _inputDecoration('Điểm đón khách *', Icons.location_on_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập điểm đón' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              decoration: _inputDecoration('Điểm đến *', Icons.flag_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập điểm đến' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Số km dự kiến', Icons.map_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _consumptionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('Mức tiêu hao (L/100km)', Icons.local_gas_station_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Các khoản phí & Dự toán
            _buildSectionHeader('Tính toán chi phí & Giá đề xuất', scheme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fuelPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Giá xăng dầu/Lít', Icons.monetization_on_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tollController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Phí cầu đường', Icons.toll_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _driverController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Công tài xế', Icons.person_pin_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _otherController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Phí phát sinh khác', Icons.more_horiz_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _profitController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Lợi nhuận mong muốn', Icons.trending_up_rounded),
            ),
            const SizedBox(height: 16),

            // Kết quả dự toán tự động
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildCalcRow('Chi phí nhiên liệu:', formatCurrency.format(_fuelCost)),
                  const SizedBox(height: 8),
                  _buildCalcRow('Giá đề xuất:', formatCurrency.format(_suggestedPrice), isBold: true, labelColor: scheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Giá chốt và đặt cọc
            _buildSectionHeader('Chốt hợp đồng & Cọc', scheme),
            const SizedBox(height: 12),
            TextFormField(
              controller: _finalPriceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Giá chốt thực tế với khách *', Icons.price_check_rounded),
              validator: (v) => v == null || v.trim().isEmpty || double.tryParse(v) == 0 ? 'Vui lòng nhập giá chốt' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Số tiền khách cọc trước', Icons.payments_outlined),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: _buildCalcRow('Số tiền còn lại cần thu:', formatCurrency.format(_remainingAmount), isBold: true, labelColor: Colors.redAccent),
            ),
            const SizedBox(height: 20),

            // Ghi chú & Trạng thái
            _buildSectionHeader('Thông tin bổ sung', scheme),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _inputDecoration('Trạng thái chuyến đi', Icons.info_outline_rounded),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                DropdownMenuItem(value: 'running', child: Text('Đang chạy')),
                DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _status = val;
                    // Reset lock check if status changed
                    if (_status == 'confirmed' || _status == 'running' || _status == 'completed') {
                      _isPriceLocked = true;
                    } else {
                      _isPriceLocked = false;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration('Ghi chú chuyến xe', Icons.note_alt_outlined),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: Text(
                _isEditMode ? 'Cập nhật chuyến xe' : 'Hoàn tất thêm chuyến',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isBold = false, Color? labelColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: labelColor,
            fontSize: isBold ? 13.5 : 12.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isBold ? 15 : 13,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
