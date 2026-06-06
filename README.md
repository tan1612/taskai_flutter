# TaskAI Pro - Trợ Lý Quản Lý Lịch Trình & Thời Khóa Biểu Thông Minh

TaskAI Pro là ứng dụng di động Flutter chuyên nghiệp thiết kế dành cho học sinh, sinh viên và người đi làm bận rộn. Ứng dụng kết hợp sức mạnh của **Trí tuệ nhân tạo (Generative AI)**, **Dự báo thời tiết thời gian thực**, **Hệ thống nhắc nhở di chuyển thông minh**, **Biểu đồ thống kê trực quan** và **Đồng bộ đám mây tức thì (Offline-First)** để tạo nên một hệ sinh thái quản lý lịch trình toàn diện, hiện đại.

---

## 🌟 Các tính năng nổi bật

### 1. Quản lý công việc thông minh (Pro Task Management)
* **Hỗ trợ đa dạng loại công việc**:
  * *Công việc thông thường (Normal Task)*: Quản lý theo hạn chót (deadline), mô tả công việc, mức độ ưu tiên, tag phân loại.
  * *Công việc di chuyển (Travel/Location Task)*: Tích hợp thông tin địa điểm xuất phát (Origin), địa điểm đến (Destination) và thời gian di chuyển dự kiến (Travel duration). Ứng dụng tự động tính ngược thời gian để nhắc nhở người dùng chuẩn bị khởi hành.
* **Mức độ ưu tiên trực quan**: Phân chia các mức Cao (High), Trung bình (Medium), Thấp (Low) với dải màu sắc nhận diện nổi bật trên giao diện danh sách nhiệm vụ.
* **Thẻ phân loại linh hoạt**: Tạo và lọc nhanh công việc theo các tag như: *Học tập, Công việc, Cá nhân, Sức khỏe, Giải trí, v.v.*
* **Đồng bộ đám mây Offline-First**:
  * Dữ liệu được lưu trữ cục bộ siêu tốc với **Hive** Database, đảm bảo ứng dụng luôn phản hồi tức thì và hoạt động mượt mà ngay cả khi không có kết nối mạng.
  * Tự động đồng bộ hóa hai chiều (Two-Way Sync) thời gian thực với **Firebase Firestore** ngay khi thiết bị trực tuyến trở lại, đi kèm thuật toán giải quyết xung đột dữ liệu thông minh.
* **Cảnh báo Email khẩn cấp (Email Alert via EmailJS)**: Khi người dùng tạo hoặc cập nhật một công việc có độ ưu tiên **Cao (High Priority)**, hệ thống sẽ tự động kích hoạt gửi một email cảnh báo chi tiết trực tiếp đến hộp thư cá nhân của người dùng để đảm bảo các nhiệm vụ quan trọng không bao giờ bị bỏ sót.

### 2. Dự báo thời tiết & Gợi ý di chuyển thông minh (AI Weather & Travel Advisor)
* **Tích hợp OpenWeatherMap API**: Tự động truy vấn dữ liệu thời tiết thời gian thực và thời tiết dự báo tại điểm đến của các công việc di chuyển.
* **Huy hiệu thời tiết nhỏ gọn (Compact Weather Badge)**: Hiển thị ngay trên thẻ công việc ngoài màn hình chính với biểu tượng trực quan, nhiệt độ hiện tại và trạng thái thời tiết ngắn gọn (ví dụ: `🌦️ Hà Nội: 29°C, mưa nhẹ`).
* **Thẻ gợi ý chi tiết (Travel Advisor Card)**: Trong màn hình chi tiết công việc, hiển thị chi tiết nhiệt độ, độ ẩm, tốc độ gió và cung cấp các lời khuyên di chuyển cực kỳ thông minh:
  * Khuyên mang theo ô/áo mưa nếu trời có mưa dông.
  * Khuyên mang mũ/nón, bổ sung nước uống nếu trời nắng nóng gay gắt (>33°C).
  * Cảnh báo giữ vững tay lái khi gió lớn (>8 m/s).
  * Động viên chuyến đi khi thời tiết mát mẻ, quang đãng.
* **Thông báo nhắc nhở kèm thời tiết**: Thông báo nhắc nhở di chuyển trước 1 tiếng sẽ tự động đính kèm dự báo thời tiết tại điểm đến kèm theo lời khuyên di chuyển tương ứng để người dùng có sự chuẩn bị tốt nhất về phương tiện cũng như trang phục.

### 3. Thời khóa biểu học sinh/sinh viên thu phóng 2D (Interactive Student Timetable)
* **Lưới thời khóa biểu 2D trực quan**: Quản lý lịch học theo tuần từ Thứ Hai đến Chủ Nhật với tối đa 15 tiết học mỗi ngày. Các môn học được hiển thị bằng các ô màu sắc riêng biệt sinh động.
* **Thu phóng & Cuộn đa hướng (Pinch-to-Zoom & 2D Pan)**: Sử dụng widget **InteractiveViewer** được tối ưu hóa cao, cho phép người dùng chụm 2 ngón tay để phóng to/thu nhỏ lịch học tự do (từ `0.5x` đến `2.0x`) và vuốt cuộn mượt mà theo cả hai chiều ngang và chiều dọc.
* **Nhắc lịch học tự động**: Tự động đặt lịch thông báo nhắc nhở trước 1 tiếng trước khi tiết học đầu tiên trong ngày bắt đầu.
* **Nút kiểm tra báo thức (Test Alarm)**: Tích hợp nút kiểm tra nhanh (Demo sau 10 giây) trực tiếp trong biểu mẫu thêm/sửa môn học để xác nhận hệ thống thông báo đẩy đang hoạt động tốt trên thiết bị.

### 4. Bong bóng Trợ lý ảo AI nổi di động (Draggable Chathead AI Assistant)
* **Giao diện Chathead nổi**: Bong bóng trợ lý ảo AI luôn hiển thị nổi trên màn hình tương tự Facebook Messenger Chathead. Người dùng có thể kéo thả tự do trên màn hình, bong bóng tự động chuyển động mượt mà và hút sát vào cạnh trái/phải màn hình khi thả tay ra.
* **Hiểu sâu ngữ cảnh lịch trình**: Khi bấm vào chathead, trợ lý AI tích hợp **Gemini API** (hoặc **Groq API với Llama 3.3 70B**) sẽ được nạp toàn bộ danh sách công việc hiện tại, mức độ ưu tiên, hạn chót, thông tin di chuyển và dữ liệu thời tiết thời gian thực. Từ đó AI có thể đưa ra câu trả lời cá nhân hóa hoàn hảo như: *"Nhiệm vụ nào của tôi cần làm trước?", "Thời tiết hôm nay có ảnh hưởng đến lịch di chuyển của tôi không?", "Hãy lập kế hoạch làm việc tốt nhất cho tôi hôm nay"*.
* **Gợi ý câu hỏi nhanh (Suggestion Chips)**: Cung cấp các nút bấm hỏi nhanh như *"Hôm nay tôi nên làm gì?", "Task nào sắp trễ?", "Thời tiết hôm nay thế nào?"* giúp tương tác tức thì mà không cần gõ phím.
* **Cơ chế phản hồi ngoại tuyến (Offline Rule Engine)**: Khi thiết bị mất kết nối mạng, ứng dụng tự động chuyển sang bộ xử lý quy tắc nội bộ để duyệt danh sách công việc từ Hive và tự động trả lời người dùng về các task quan trọng, sắp đến hạn.

### 5. Thống kê & Phân tích trực quan (Visual Analytics & Charts)
* **Đo lường tiến độ trong ngày**: Biểu đồ tròn sinh động hiển thị tỷ lệ phần trăm công việc đã hoàn thành so với tổng số lượng công việc của ngày hiện tại.
* **Phân tích số liệu tổng quan**: Dashboard tổng kết rõ ràng số lượng task: *Tổng số, Đang chờ (Pending), Đã hoàn thành (Completed), và Trễ hạn (Overdue)*.
* **Lịch sử hoạt động 7 ngày gần nhất**: Sử dụng thư viện **fl_chart** để vẽ biểu đồ cột thể hiện số lượng công việc hoàn thành mỗi ngày trong tuần qua.
* **Lời khuyên năng suất thông minh**: Hệ thống tự động phân tích hành vi hoàn thành công việc và đưa ra lời khuyên hữu ích (ví dụ: nhắc nhở tập trung hoàn thành các nhóm công việc/tag đang bị trễ hạn nhiều nhất).

### 6. Xuất lịch biểu ngoại vi (Calendar Export .ics)
* **Định dạng chuẩn quốc tế (.ics)**: Cho phép kết xuất toàn bộ công việc và lịch trình trong tuần ra tệp tin đuôi `.ics` tiêu chuẩn.
* **Chia sẻ tức thì**: Sử dụng bảng chia sẻ hệ thống (System Share Sheet) để gửi tệp tin này sang các ứng dụng lịch khác như **Google Calendar**, **Apple Calendar**, hoặc **Outlook** để quản lý đồng bộ.

### 7. Cài đặt & Cá nhân hóa (Settings & UI Personalization)
* **Xác thực tài khoản Pro**: Đăng nhập/Đăng ký tài khoản nhanh chóng thông qua **Firebase Authentication**.
* **Chế độ Guest Mode**: Cho phép trải nghiệm toàn bộ các tính năng cốt lõi của ứng dụng offline mà không cần đăng ký tài khoản.
* **Nhắc nhở lên kế hoạch tuần mới**: Tự động gửi thông báo đẩy và email nhắc nhở vào lúc **19:00 tối Chủ Nhật hàng tuần** để giúp người dùng chuẩn bị sẵn sàng cho một tuần làm việc mới hiệu quả.
* **Giao diện Sáng/Tối mượt mà (Light/Dark Theme Switcher)**: Chuyển đổi theme mượt mà toàn ứng dụng. Tự động điều chỉnh màu sắc văn bản thanh trạng thái hệ thống của điện thoại (Status Bar text color) để đảm bảo các thông tin pin, wifi, cột sóng luôn hiển thị rõ ràng trên cả nền sáng lẫn nền tối.

---

## 🛠️ Công nghệ sử dụng (Tech Stack)

Ứng dụng được xây dựng trên ngôn ngữ **Dart** & framework **Flutter** với các thư viện chính:
* **State Management**: `Flutter Riverpod` (đảm bảo kiến trúc sạch, dễ bảo trì, mở rộng và viết unit test).
* **Local Database**: `Hive` & `Hive Flutter` (Lưu trữ offline-first tốc độ cực cao dưới dạng Key-Value).
* **Cloud Database & Auth**: `Cloud Firestore` & `Firebase Auth` (Đồng bộ đám mây và xác thực tài khoản).
* **Network & API Client**: `Dio` (Quản lý HTTP requests, timeouts, interceptors hiệu quả).
* **AI Engine**: `google_generative_ai` (Gemini API) / `Groq API` (Llama 3.3).
* **Charts**: `fl_chart` (Biểu đồ tròn tiến độ và biểu đồ cột lịch sử).
* **Notifications**: `flutter_local_notifications` (Lập lịch thông báo đẩy định kỳ và thông báo tức thì sát giờ).
* **Múi giờ**: `timezone` & `flutter_timezone` (Xác định múi giờ hệ thống để tránh lệch giờ khi lên lịch định kỳ).
* **Chia sẻ tệp**: `share_plus` & `path_provider` (Hỗ trợ xuất và chia sẻ tệp lịch `.ics`).
* **Quản lý biến môi trường**: `flutter_dotenv`.
* **Gửi Email cảnh báo**: `Dio` gọi API của `EmailJS`.

---

## 📂 Cấu trúc thư mục dự án (Project Structure)

Mã nguồn được tổ chức theo kiến trúc phân lớp (Clean Architecture / Feature-First) rõ ràng:
```text
lib/
├── core/                       # Các cấu hình và tiện ích dùng chung toàn ứng dụng
│   ├── constants/              # Các hằng số định nghĩa sẵn
│   ├── theme/                  # Định nghĩa AppTheme (Light/Dark mode, bảng màu)
│   └── utils/                  # Các tiện ích (CalendarExporter, DateUtils)
├── data/                       # Lớp dữ liệu (Models, Repositories, Services)
│   ├── models/                 # Hive Adapters & Models (TaskModel, TimetableSlot, UserModel)
│   ├── repositories/           # Nguồn dữ liệu (WeatherRepository, TaskRepository)
│   └── services/               # Các dịch vụ bên thứ ba (ApiService, NotificationService, EmailService, HiveService)
├── presentation/               # Giao diện người dùng (UI - Screens, Widgets, Providers)
│   ├── providers/              # State Providers của Riverpod (Task, Timetable, Auth, Weather, Theme)
│   ├── screens/                # Các màn hình chính (Home, Schedule, Stats, Settings, Chatbot, Detail, Auth...)
│   └── widgets/                # Các widget tái sử dụng (TimetableGridView, TaskCard, WeatherWidget...)
├── app.dart                    # Widget gốc của ứng dụng (Cấu hình Theme, Status Bar, Auth Router)
└── main.dart                   # Điểm khởi chạy ứng dụng (Khởi tạo Hive, Firebase, Notification, DotEnv)
```

---

## 🚀 Hướng dẫn cài đặt & Chạy dự án

### 1. Cài đặt các gói phụ thuộc
Chạy lệnh sau tại thư mục gốc của dự án để tải về các package cần thiết:
```bash
flutter pub get
```

### 2. Cấu hình file môi trường `.env`
Sao chép file mẫu `.env.example` thành file `.env` ở thư mục gốc của dự án:
```bash
cp .env.example .env
```
Mở file `.env` mới tạo và điền các khóa API tương ứng của bạn:
```env
# API Key của Gemini AI (hoặc Groq API Key)
GEMINI_API_KEY=AIzaSy...

# API Key lấy thông tin thời tiết từ OpenWeatherMap
OPENWEATHER_API_KEY=afe87f...

# Cấu hình dịch vụ gửi Email khẩn cấp (EmailJS)
EMAILJS_SERVICE_ID=service_...
EMAILJS_TEMPLATE_ID=template_...
EMAILJS_PUBLIC_KEY=Ceg...
RECEIVER_EMAIL=your_email@gmail.com
```

### 3. Biên dịch Adapter dữ liệu (Hive Code Generation)
Do ứng dụng sử dụng Hive để lưu trữ offline, bạn cần chạy build_runner để sinh ra các adapter lưu trữ (`.g.dart`):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Chạy ứng dụng trên thiết bị / trình giả lập
```bash
flutter run
```

---

## 📱 Cấu hình Quyền thông báo (Notification Configurations)

### Cấu hình trên Android
Ứng dụng yêu cầu quyền gửi thông báo chính xác (Exact Alarm) để nhắc nhở sát giờ deadline/tiết học. Hãy chắc chắn rằng trong file `android/app/src/main/AndroidManifest.xml` đã khai báo các quyền sau:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### Cấu hình trên iOS (Bao gồm cài đặt qua TrollStore)
* Ứng dụng hỗ trợ cấu hình quyền thông báo đầy đủ khi khởi chạy lần đầu thông qua hộp thoại cấp quyền của hệ thống.
* **Lưu ý đối với thiết bị cài đặt qua TrollStore (tệp .ipa)**: Một số phiên bản iOS hoặc TrollStore có thể chặn quyền chạy nền hoặc lên lịch `zonedSchedule` (do thiếu sandbox container entitlements hoặc timezone database).
* Để khắc phục hạn chế này, TaskAI Pro tích hợp một cơ chế fallback thông minh sử dụng `Future.delayed` để kích hoạt trực tiếp thông báo thử (`show`) trên thiết bị iOS sau 10 giây khi người dùng bấm nút test trên giao diện cài đặt hoặc tạo task test. Cơ chế này giúp lập trình viên và người dùng xác nhận tính năng thông báo luôn sẵn sàng hoạt động mà không bị ảnh hưởng bởi lỗi timezone trên TrollStore.

---

## 🛠️ Xử lý sự cố thường gặp (Troubleshooting)

1. **Lỗi không đồng bộ được dữ liệu**:
   * Kiểm tra xem bạn đã đăng nhập tài khoản chưa (ở màn hình cài đặt / thông tin cá nhân).
   * Kiểm tra kết nối Internet trên thiết bị. Khi có mạng, ứng dụng sẽ tự động chạy tiến trình đồng bộ ngầm.
2. **Lỗi thiếu các file adapter Hive (`*.g.dart`)**:
   * Chạy lại lệnh biên dịch code generator: `flutter pub run build_runner build --delete-conflicting-outputs`.
3. **Không nhận được email khi tạo Task Cao (High Priority)**:
   * Kiểm tra xem bạn đã điền đúng các thông tin cấu hình `EMAILJS_*` và `RECEIVER_EMAIL` trong file `.env` hay chưa.
   * Kiểm tra hạn mức (Quota) của tài khoản EmailJS (tài khoản miễn phí giới hạn 200 email/tháng).
