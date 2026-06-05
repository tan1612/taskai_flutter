import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taskai/data/models/task_model.dart';

class CalendarExporter {
  static String _toIcsDateTime(DateTime dt) {
    final utc = dt.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$year$month${day}T$hour$minute${second}Z';
  }

  static Future<void> exportTasksToIcs(List<TaskModel> tasks) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//TaskAI Pro//TaskAI Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    for (final task in tasks) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${task.id}');
      buffer.writeln('DTSTAMP:${_toIcsDateTime(task.createdAt)}');
      
      final start = task.isLocationTask && task.startTime != null 
          ? task.startTime! 
          : task.deadline;
      final end = task.isLocationTask && task.endTime != null 
          ? task.endTime! 
          : start.add(const Duration(hours: 1));

      buffer.writeln('DTSTART:${_toIcsDateTime(start)}');
      buffer.writeln('DTEND:${_toIcsDateTime(end)}');
      
      // Clean up string fields to avoid syntax breaks
      final summary = task.title.replaceAll('\n', ' ').replaceAll(',', '\\,');
      buffer.writeln('SUMMARY:$summary');

      final description = task.description.replaceAll('\n', '\\n').replaceAll(',', '\\,');
      buffer.writeln('DESCRIPTION:$description');

      if (task.isLocationTask && task.locationName != null && task.locationName!.isNotEmpty) {
        final loc = task.locationName!.replaceAll('\n', ' ').replaceAll(',', '\\,');
        buffer.writeln('LOCATION:$loc');
      }

      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');

    final icsContent = buffer.toString();

    // Write file to temporary folder
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/taskai_schedule.ics');
    await file.writeAsString(icsContent);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Lịch biểu từ TaskAI Pro',
      text: 'Gửi bạn lịch biểu được xuất từ ứng dụng TaskAI Pro.',
    );
  }
}
