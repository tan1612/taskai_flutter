import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/weather_model.dart';
import 'package:taskai/presentation/providers/app_providers.dart';

final weatherProvider = FutureProvider<WeatherModel>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.getCurrentWeather();
});

final forecastWeatherProvider = FutureProvider<ForecastWeatherModel>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.getForecastWeather();
});

final destinationWeatherProvider = FutureProvider.family<WeatherModel, String>((ref, city) async {
  if (city.isEmpty || city.trim() == 'Điểm đến') {
    throw Exception('No valid city name');
  }
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.getCurrentWeather(city: city.trim());
});