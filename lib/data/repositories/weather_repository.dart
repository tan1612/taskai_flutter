import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/data/models/weather_model.dart';
import 'package:taskai/data/services/api_service.dart';

class WeatherRepository {
  final ApiService _apiService;

  WeatherRepository(this._apiService);

  Future<WeatherModel> getCurrentWeather({
    String city = AppConstants.defaultCity,
  }) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? 'YOUR_API_KEY';

    print('OPENWEATHER API KEY = $apiKey');

    if (apiKey.trim().isEmpty || apiKey.trim() == 'YOUR_API_KEY') {
      return _fallbackWeather();
    }

    try {
      final response = await _apiService.dio.get(
        AppConstants.weatherBaseUrl,
        queryParameters: {
          'q': city,
          'appid': apiKey.trim(),
          'units': 'metric',
          'lang': 'vi',
        },
      );

      print('OPENWEATHER SUCCESS = ${response.data}');

      return WeatherModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('OPENWEATHER ERROR STATUS = ${e.response?.statusCode}');
      print('OPENWEATHER ERROR DATA = ${e.response?.data}');
      return _fallbackWeather();
    } catch (e) {
      print('OPENWEATHER UNKNOWN ERROR = $e');
      return _fallbackWeather();
    }
  }

  Future<ForecastWeatherModel> getForecastWeather({
    String city = AppConstants.defaultCity,
  }) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? 'YOUR_API_KEY';

    if (apiKey.trim().isEmpty || apiKey.trim() == 'YOUR_API_KEY') {
      return _fallbackForecast();
    }

    try {
      final response = await _apiService.dio.get(
        'https://api.openweathermap.org/data/2.5/forecast',
        queryParameters: {
          'q': city,
          'appid': apiKey.trim(),
          'units': 'metric',
          'lang': 'vi',
        },
      );

      print('OPENWEATHER FORECAST SUCCESS = ${response.data}');

      return ForecastWeatherModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print('OPENWEATHER FORECAST ERROR STATUS = ${e.response?.statusCode}');
      print('OPENWEATHER FORECAST ERROR DATA = ${e.response?.data}');
      return _fallbackForecast();
    } catch (e) {
      print('OPENWEATHER FORECAST UNKNOWN ERROR = $e');
      return _fallbackForecast();
    }
  }

  WeatherModel _fallbackWeather() {
    return WeatherModel(
      cityName: 'Ho Chi Minh City',
      temperature: 30,
      description: 'thời tiết ổn định',
      humidity: 70,
      windSpeed: 2.5,
      icon: '01d',
    );
  }

  ForecastWeatherModel _fallbackForecast() {
    final now = DateTime.now();

    return ForecastWeatherModel(
      cityName: 'Ho Chi Minh City',
      items: List.generate(16, (index) {
        return ForecastWeatherItem(
          time: now.add(Duration(hours: index * 3)),
          temperature: 30,
          description: 'thời tiết ổn định',
          humidity: 70,
          windSpeed: 2.5,
          icon: '01d',
        );
      }),
    );
  }
}