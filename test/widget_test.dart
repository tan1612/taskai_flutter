import 'package:flutter_test/flutter_test.dart';
import 'package:taskai/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils Unit Tests', () {
    test('dateTime formats correctly', () {
      final date = DateTime(2026, 6, 5, 15, 30);
      final formatted = AppDateUtils.dateTime(date);
      expect(formatted, '15:30 - 05/06/2026');
    });

    test('isSameDayOnly identifies same days', () {
      final date1 = DateTime(2026, 6, 5, 10, 0);
      final date2 = DateTime(2026, 6, 5, 18, 45);
      final differentDate = DateTime(2026, 6, 6, 10, 0);

      expect(AppDateUtils.isSameDayOnly(date1, date2), isTrue);
      expect(AppDateUtils.isSameDayOnly(date1, differentDate), isFalse);
    });
  });
}
