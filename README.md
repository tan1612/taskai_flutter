# TaskAI

App Flutter quản lý công việc thông minh, dùng Riverpod, Hive, Dio, Gemini API, OpenWeatherMap, fl_chart và local notification.

## Chạy project

```bash
flutter pub get
cp .env.example .env
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Mở file `.env` và thay API key thật:

```env
GEMINI_API_KEY=...
OPENWEATHER_API_KEY=...
```

Nếu chạy Android, hãy kiểm tra quyền notification trong `android/app/src/main/AndroidManifest.xml`.
