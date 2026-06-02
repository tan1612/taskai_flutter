import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/task_model.dart';
import 'package:taskai/presentation/providers/task_provider.dart';
import 'package:uuid/uuid.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  final _locationNameController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _googleMapsUrlController = TextEditingController();

  late DateTime _deadline;
  DateTime? _startTime;
  DateTime? _endTime;

  TaskPriority _priority = TaskPriority.medium;
  TaskType _type = TaskType.normal;

  int _reminderMinutes = 60;
  int _travelMinutes = 30;
  int _departReminderMinutes = 10;

  bool _saving = false;

  bool get isEdit => widget.task != null;

  static const List<_ReminderOption> _normalReminderOptions = [
    _ReminderOption(0, 'Không nhắc'),
    _ReminderOption(-1, 'Demo sau 10 giây'),
    _ReminderOption(5, 'Trước 5 phút'),
    _ReminderOption(10, 'Trước 10 phút'),
    _ReminderOption(15, 'Trước 15 phút'),
    _ReminderOption(30, 'Trước 30 phút'),
    _ReminderOption(60, 'Trước 1 tiếng'),
    _ReminderOption(1440, 'Trước 1 ngày'),
  ];

  static const List<_ReminderOption> _locationReminderOptions = [
    _ReminderOption(0, 'Không nhắc'),
    _ReminderOption(-1, 'Demo sau 10 giây'),
    _ReminderOption(5, 'Nhắc trước giờ đi 5 phút'),
    _ReminderOption(10, 'Nhắc trước giờ đi 10 phút'),
    _ReminderOption(15, 'Nhắc trước giờ đi 15 phút'),
    _ReminderOption(30, 'Nhắc trước giờ đi 30 phút'),
  ];

  static const List<_TravelOption> _travelOptions = [
    _TravelOption(5, '5 phút'),
    _TravelOption(10, '10 phút'),
    _TravelOption(15, '15 phút'),
    _TravelOption(20, '20 phút'),
    _TravelOption(30, '30 phút'),
    _TravelOption(45, '45 phút'),
    _TravelOption(60, '1 tiếng'),
    _TravelOption(90, '1 tiếng 30 phút'),
    _TravelOption(120, '2 tiếng'),
  ];

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    _tagController.text = task?.tag ?? 'Học tập';

    _deadline = task?.deadline ?? DateTime.now().add(const Duration(hours: 2));
    _priority = task?.priority ?? TaskPriority.medium;
    _type = task?.type ?? TaskType.normal;

    _reminderMinutes = task?.reminderMinutes ?? 60;
    _travelMinutes = task?.travelMinutes ?? 30;
    _departReminderMinutes = task?.departReminderMinutes ?? 10;

    _startTime = task?.startTime;
    _endTime = task?.endTime;

    _locationNameController.text =
        task?.locationName ?? task?.destinationName ?? '';
    _locationAddressController.text = task?.locationAddress ?? '';
    _googleMapsUrlController.text = task?.googleMapsUrl ?? '';

    final now = DateTime.now();

    if (!isEdit && _deadline.isBefore(now)) {
      _deadline = now.add(const Duration(hours: 2));
    }

    if (!isEdit && _type == TaskType.location) {
      _startTime ??= now.add(const Duration(hours: 1));
      _endTime ??= _startTime!.add(const Duration(hours: 1));
      _deadline = _endTime!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _locationNameController.dispose();
    _locationAddressController.dispose();
    _googleMapsUrlController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isPast(DateTime value) {
    return value.isBefore(DateTime.now());
  }

  DateTime? get _calculatedDepartureTime {
    if (_type != TaskType.location || _startTime == null) return null;

    return _startTime!.subtract(
      Duration(minutes: _travelMinutes),
    );
  }

  DateTime? get _calculatedNotificationTime {
    final departureTime = _calculatedDepartureTime;

    if (departureTime == null) return null;

    return departureTime.subtract(
      Duration(minutes: _departReminderMinutes),
    );
  }

  String get _departurePreview {
    if (_type != TaskType.location || _startTime == null) {
      return 'Chưa có';
    }

    final departureTime = _calculatedDepartureTime;

    if (departureTime == null) {
      return 'Chưa có';
    }

    if (_reminderMinutes == -1) {
      return 'Demo: thông báo sau 10 giây';
    }

    if (_reminderMinutes == 0) {
      return 'Nên xuất phát lúc ${_formatTime(departureTime)}. Không bật thông báo.';
    }

    final notifyTime = _calculatedNotificationTime;

    if (notifyTime == null) {
      return 'Nên xuất phát lúc ${_formatTime(departureTime)}.';
    }

    return 'Nên xuất phát lúc ${_formatTime(departureTime)}, thông báo lúc ${_formatTime(notifyTime)}';
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDate,
  }) async {
    final now = DateTime.now();

    final safeInitialDate = initialDate.isBefore(now) ? now : initialDate;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2035),
    );

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(safeInitialDate),
    );

    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await _pickDateTime(initialDate: _deadline);
    if (picked == null) return;

    if (_isPast(picked)) {
      if (!mounted) return;
      _showMessage('Deadline không được ở quá khứ');
      return;
    }

    setState(() {
      _deadline = picked;
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await _pickDateTime(
      initialDate: _startTime ?? DateTime.now().add(const Duration(hours: 1)),
    );

    if (picked == null) return;

    if (_isPast(picked)) {
      if (!mounted) return;
      _showMessage('Giờ bắt đầu không được ở quá khứ');
      return;
    }

    setState(() {
      _startTime = picked;

      if (_endTime == null ||
          _endTime!.isBefore(picked) ||
          _endTime!.isAtSameMomentAs(picked)) {
        _endTime = picked.add(const Duration(hours: 1));
      }

      _deadline = _endTime ?? picked;
    });
  }

  Future<void> _pickEndTime() async {
    final base = _endTime ??
        _startTime?.add(const Duration(hours: 1)) ??
        DateTime.now().add(const Duration(hours: 2));

    final picked = await _pickDateTime(initialDate: base);

    if (picked == null) return;

    if (_startTime != null &&
        (picked.isBefore(_startTime!) ||
            picked.isAtSameMomentAs(_startTime!))) {
      if (!mounted) return;

      _showMessage('Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }

    setState(() {
      _endTime = picked;
      _deadline = picked;
    });
  }

  bool _validateTimeRules() {
    final now = DateTime.now();

    if (_type == TaskType.normal) {
      if (_deadline.isBefore(now)) {
        _showMessage('Deadline không được ở quá khứ');
        return false;
      }

      if (_reminderMinutes != -1 && _reminderMinutes != 0) {
        final notificationTime = _deadline.subtract(
          Duration(minutes: _reminderMinutes),
        );

        if (notificationTime.isBefore(now)) {
          _showMessage(
            'Thời điểm nhắc deadline đã qua. Hãy chọn deadline xa hơn hoặc giảm thời gian nhắc.',
          );
          return false;
        }
      }

      return true;
    }

    if (_startTime == null) {
      _showMessage('Vui lòng chọn giờ bắt đầu');
      return false;
    }

    if (_endTime == null) {
      _showMessage('Vui lòng chọn giờ kết thúc');
      return false;
    }

    if (_startTime!.isBefore(now)) {
      _showMessage('Giờ bắt đầu không được ở quá khứ');
      return false;
    }

    if (_endTime!.isBefore(_startTime!) ||
        _endTime!.isAtSameMomentAs(_startTime!)) {
      _showMessage('Giờ kết thúc phải sau giờ bắt đầu');
      return false;
    }

    final departureTime = _calculatedDepartureTime;

    if (departureTime == null) {
      _showMessage('Không tính được giờ xuất phát');
      return false;
    }

    if (departureTime.isBefore(now)) {
      _showMessage(
        'Giờ xuất phát đã qua. Hãy chọn giờ bắt đầu xa hơn hoặc giảm thời gian di chuyển.',
      );
      return false;
    }

    if (_reminderMinutes != -1 && _reminderMinutes != 0) {
      final notificationTime = _calculatedNotificationTime;

      if (notificationTime == null) {
        _showMessage('Không tính được thời điểm thông báo');
        return false;
      }

      if (notificationTime.isBefore(now)) {
        _showMessage(
          'Thời điểm thông báo đã qua. Hãy chọn giờ bắt đầu xa hơn hoặc giảm thời gian nhắc.',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_validateTimeRules()) return;

    if (_type == TaskType.location) {
      if (_locationNameController.text.trim().isEmpty) {
        _showMessage('Vui lòng nhập địa điểm');
        return;
      }

      if (_locationAddressController.text.trim().isEmpty) {
        _showMessage('Vui lòng nhập địa chỉ hoặc ghi chú địa điểm');
        return;
      }

      final mapsUrl = _googleMapsUrlController.text.trim();

      if (mapsUrl.isNotEmpty) {
        final uri = Uri.tryParse(mapsUrl);

        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          _showMessage('Link Google Maps không hợp lệ');
          return;
        }
      }
    }

    setState(() => _saving = true);

    try {
      final old = widget.task;

      final task = TaskModel(
        id: old?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline:
            _type == TaskType.location ? (_endTime ?? _deadline) : _deadline,
        priority: _priority,
        tag: _tagController.text.trim().isEmpty
            ? 'Khác'
            : _tagController.text.trim(),
        isDone: old?.isDone ?? false,
        createdAt: old?.createdAt ?? DateTime.now(),
        reminderMinutes: _reminderMinutes,
        type: _type,
        startTime: _type == TaskType.location ? _startTime : null,
        endTime: _type == TaskType.location ? _endTime : null,
        locationName: _type == TaskType.location
            ? _locationNameController.text.trim()
            : null,
        locationAddress: _type == TaskType.location
            ? _locationAddressController.text.trim()
            : null,
        googleMapsUrl: _type == TaskType.location
            ? _googleMapsUrlController.text.trim()
            : null,
        originName: null,
        destinationName: _type == TaskType.location
            ? _locationNameController.text.trim()
            : null,
        travelMinutes: _travelMinutes,
        departReminderMinutes: _departReminderMinutes,
      );

      await ref
          .read(taskProvider.notifier)
          .addOrUpdate(task)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo công việc: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocationTask = _type == TaskType.location;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa Task' : 'Tạo Task',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TaskType>(
              segments: const [
                ButtonSegment<TaskType>(
                  value: TaskType.normal,
                  icon: Icon(Icons.task_alt_rounded),
                  label: Text('Thông thường'),
                ),
                ButtonSegment<TaskType>(
                  value: TaskType.location,
                  icon: Icon(Icons.route_rounded),
                  label: Text('Có di chuyển'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() {
                  _type = values.first;

                  if (_type == TaskType.location) {
                    _startTime ??= DateTime.now().add(const Duration(hours: 1));
                    _endTime ??= _startTime!.add(const Duration(hours: 1));
                    _deadline = _endTime!;

                    _reminderMinutes = -1;
                  } else {
                    _reminderMinutes = 60;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên công việc',
                prefixIcon: Icon(Icons.task_alt_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên công việc';
                }

                if (value.trim().length < 3) {
                  return 'Tên công việc tối thiểu 3 ký tự';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            if (!isLocationTask) ...[
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  child: Text(_formatDateTime(_deadline)),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (isLocationTask) ...[
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Giờ bắt đầu lịch',
                    prefixIcon: Icon(Icons.play_circle_rounded),
                  ),
                  child: Text(
                    _startTime == null
                        ? 'Chưa chọn'
                        : _formatDateTime(_startTime!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Giờ kết thúc lịch',
                    prefixIcon: Icon(Icons.stop_circle_rounded),
                  ),
                  child: Text(
                    _endTime == null
                        ? 'Chưa chọn'
                        : _formatDateTime(_endTime!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  hintText: 'VD: Trường đại học, Công ty, Quán cafe',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
                validator: (value) {
                  if (_type == TaskType.location &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập địa điểm';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationAddressController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ / ghi chú địa điểm',
                  hintText: 'VD: 123 Nguyễn Huệ, Quận 1',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
                validator: (value) {
                  if (_type == TaskType.location &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập địa chỉ hoặc ghi chú địa điểm';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _googleMapsUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link Google Maps',
                  hintText: 'Dán link Google Maps nếu có',
                  prefixIcon: Icon(Icons.map_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) return null;

                  final uri = Uri.tryParse(text);

                  if (uri == null ||
                      !(uri.isScheme('http') || uri.isScheme('https'))) {
                    return 'Link Google Maps không hợp lệ';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _travelMinutes,
                decoration: const InputDecoration(
                  labelText: 'Thời gian di chuyển dự kiến',
                  prefixIcon: Icon(Icons.directions_car_rounded),
                ),
                items: _travelOptions
                    .map(
                      (option) => DropdownMenuItem<int>(
                        value: option.minutes,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _travelMinutes = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _departReminderMinutes,
                decoration: const InputDecoration(
                  labelText: 'Nhắc trước giờ xuất phát',
                  prefixIcon: Icon(Icons.alarm_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Đúng giờ xuất phát')),
                  DropdownMenuItem(value: 5, child: Text('Trước 5 phút')),
                  DropdownMenuItem(value: 10, child: Text('Trước 10 phút')),
                  DropdownMenuItem(value: 15, child: Text('Trước 15 phút')),
                  DropdownMenuItem(value: 30, child: Text('Trước 30 phút')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _departReminderMinutes = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _departurePreview,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Độ ưu tiên',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag',
                hintText: 'VD: Học tập, Công việc, Cá nhân',
                prefixIcon: Icon(Icons.sell_rounded),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _reminderMinutes,
              decoration: InputDecoration(
                labelText: isLocationTask
                    ? 'Chế độ nhắc di chuyển'
                    : 'Nhắc trước deadline',
                prefixIcon: const Icon(Icons.notifications_active_rounded),
              ),
              items:
                  (isLocationTask ? _locationReminderOptions : _normalReminderOptions)
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.minutes,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _reminderMinutes = value);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo công việc'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderOption {
  final int minutes;
  final String label;

  const _ReminderOption(this.minutes, this.label);
}

class _TravelOption {
  final int minutes;
  final String label;

  const _TravelOption(this.minutes, this.label);
}