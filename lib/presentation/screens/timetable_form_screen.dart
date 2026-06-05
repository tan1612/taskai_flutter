import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/data/models/timetable_slot.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:uuid/uuid.dart';

class TimetableFormScreen extends ConsumerStatefulWidget {
  final TimetableSlot? slot;

  const TimetableFormScreen({super.key, this.slot});

  @override
  ConsumerState<TimetableFormScreen> createState() => _TimetableFormScreenState();
}

class _TimetableFormScreenState extends ConsumerState<TimetableFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectNameController = TextEditingController();
  final _roomController = TextEditingController();

  int _dayOfWeek = 1; // 1 = Thứ 2, 7 = Chủ Nhật
  int _startPeriod = 1;
  int _endPeriod = 3;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));

  bool _saving = false;

  bool get isEdit => widget.slot != null;

  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    if (slot != null) {
      _subjectNameController.text = slot.subjectName;
      _roomController.text = slot.room;
      _dayOfWeek = slot.dayOfWeek;
      _startPeriod = slot.startPeriod;
      _endPeriod = slot.endPeriod;
      _startDate = slot.startDate;
      _endDate = slot.endDate;
    }
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _testClassReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final tempSlot = TimetableSlot(
      id: widget.slot?.id ?? 'temp_test_id',
      subjectName: _subjectNameController.text.trim(),
      room: _roomController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startPeriod: _startPeriod,
      endPeriod: _endPeriod,
      startDate: _startDate,
      endDate: _endDate,
    );

    try {
      await ref.read(notificationServiceProvider).scheduleTimetableSlotTestAfter10Seconds(tempSlot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đặt nhắc nhở thử 10s cho môn này. Vui lòng chờ thông báo.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kiểm tra thông báo: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _deleteSlot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa môn học', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa môn "${widget.slot!.subjectName}" khỏi thời khóa biểu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _saving = true);
      try {
        await ref.read(timetableProvider.notifier).delete(widget.slot!.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa môn học: $e')),
        );
      }
    }
  }

  Future<void> _saveSlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final slot = TimetableSlot(
      id: widget.slot?.id ?? const Uuid().v4(),
      subjectName: _subjectNameController.text.trim(),
      room: _roomController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startPeriod: _startPeriod,
      endPeriod: _endPeriod,
      startDate: _startDate,
      endDate: _endDate,
    );

    try {
      await ref.read(timetableProvider.notifier).addOrUpdate(slot);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu môn học: $e')),
      );
    }
  }

  String _getDayLabel(int day) {
    if (day == 7) return 'Chủ Nhật';
    return 'Thứ ${day + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa môn học' : 'Thêm môn học',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
              onPressed: _saving ? null : _deleteSlot,
              tooltip: 'Xóa môn học',
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tên môn học
                  TextFormField(
                    controller: _subjectNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên môn học *',
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên môn học';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phòng học
                  TextFormField(
                    controller: _roomController,
                    decoration: const InputDecoration(
                      labelText: 'Phòng học',
                      prefixIcon: Icon(Icons.meeting_room_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ngày học (Thứ)
                  DropdownButtonFormField<int>(
                    value: _dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Ngày học (Thứ)',
                      prefixIcon: Icon(Icons.today_rounded),
                    ),
                    items: List.generate(7, (index) => index + 1).map((day) {
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Text(_getDayLabel(day)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfWeek = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tiết bắt đầu & Tiết kết thúc
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _startPeriod,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tiết bắt đầu',
                            prefixIcon: Icon(Icons.start_rounded),
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return List.generate(15, (index) => index + 1).map((period) {
                              return Text(
                                'Tiết $period',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList();
                          },
                          items: List.generate(15, (index) => index + 1).map((period) {
                            return DropdownMenuItem<int>(
                              value: period,
                              child: Text('Tiết $period (${TimetableSlot.periodStartTimes[period]})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _startPeriod = val;
                                if (_endPeriod < _startPeriod) {
                                  _endPeriod = _startPeriod;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _endPeriod,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tiết kết thúc',
                            prefixIcon: Icon(Icons.last_page_rounded),
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return List.generate(15, (index) => index + 1).map((period) {
                              return Text(
                                'Tiết $period',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList();
                          },
                          items: List.generate(15, (index) => index + 1).map((period) {
                            return DropdownMenuItem<int>(
                              value: period,
                              child: Text('Tiết $period (${TimetableSlot.periodEndTimes[period]})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _endPeriod = val);
                          },
                          validator: (value) {
                            if (value != null && value < _startPeriod) {
                              return 'Kết thúc phải >= bắt đầu';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ngày bắt đầu & Ngày kết thúc
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _startDate = picked;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate.add(const Duration(days: 90));
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Ngày bắt đầu',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                            ),
                            child: Text(
                              '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _endDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Ngày kết thúc',
                              prefixIcon: Icon(Icons.event_rounded),
                            ),
                            child: Text(
                              '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Button Lưu
                  FilledButton(
                    onPressed: _saveSlot,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('LƯU MÔN HỌC', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  // Button Test Nhắc Nhở
                  OutlinedButton.icon(
                    onPressed: _testClassReminder,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('TEST BÁO THỨC TRƯỚC 10 GIÂY'),
                  ),
                ],
              ),
            ),
    );
  }
}
