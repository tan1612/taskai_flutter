import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/data/models/trip_model.dart';
import 'package:taskai/data/models/car_model.dart';
import 'package:taskai/data/models/fuel_price_model.dart';
import 'package:taskai/data/models/daily_log_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Đăng ký các adapter mới cho Du Lịch Năm Ái
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TripModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CarModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(FuelPriceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(DailyLogModelAdapter());
    }

    // Mở settings box lưu cài đặt hệ thống (dark mode, thông báo)
    await Hive.openBox<dynamic>(AppConstants.settingsBox);

    // Mở các box mới du lịch
    await Hive.openBox<TripModel>(AppConstants.tripBox);
    await Hive.openBox<CarModel>(AppConstants.carBox);
    await Hive.openBox<FuelPriceModel>(AppConstants.fuelPriceBox);
    await Hive.openBox<DailyLogModel>(AppConstants.dailyLogBox);
  }

  Box<dynamic> get settingsBox => Hive.box<dynamic>(AppConstants.settingsBox);

  // Getters cho các box mới du lịch
  Box<TripModel> get tripBox => Hive.box<TripModel>(AppConstants.tripBox);
  Box<CarModel> get carBox => Hive.box<CarModel>(AppConstants.carBox);
  Box<FuelPriceModel> get fuelPriceBox => Hive.box<FuelPriceModel>(AppConstants.fuelPriceBox);
  Box<DailyLogModel> get dailyLogBox => Hive.box<DailyLogModel>(AppConstants.dailyLogBox);
}