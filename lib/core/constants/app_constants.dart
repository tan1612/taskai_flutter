class AppConstants {
  static const String appName = 'TaskAI';

  static const String taskBox = 'tasks';
  static const String settingsBox = 'settings';
  static const String timetableBox = 'timetable';

  static const String defaultCity = 'Ho Chi Minh City';

  static const String geminiModel = 'gemini-2.0-flash';

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent';

  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
}