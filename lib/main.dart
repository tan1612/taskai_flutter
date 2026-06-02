import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taskai/app.dart';
import 'package:taskai/data/services/hive_service.dart';
import 'package:taskai/data/services/notification_service.dart';
import 'package:taskai/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('vi_VN');

  await HiveService.init();

  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: TaskAIApp(),
    ),
  );
}