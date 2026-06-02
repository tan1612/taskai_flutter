class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final String icon;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).isNotEmpty
        ? json['weather'][0] as Map<String, dynamic>
        : <String, dynamic>{};

    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};

    return WeatherModel(
      cityName: json['name']?.toString() ?? 'Không rõ',
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      description: weather['description']?.toString() ?? 'Không có dữ liệu',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      icon: weather['icon']?.toString() ?? '01d',
    );
  }
}

class ForecastWeatherModel {
  final String cityName;
  final List<ForecastWeatherItem> items;

  ForecastWeatherModel({
    required this.cityName,
    required this.items,
  });

  factory ForecastWeatherModel.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>? ?? {};
    final list = json['list'] as List? ?? [];

    return ForecastWeatherModel(
      cityName: city['name']?.toString() ?? 'Không rõ',
      items: list
          .whereType<Map<String, dynamic>>()
          .map(ForecastWeatherItem.fromJson)
          .toList(),
    );
  }

  ForecastWeatherItem? nearestTo(DateTime target) {
    if (items.isEmpty) return null;

    ForecastWeatherItem nearest = items.first;
    var minDiff = nearest.time.difference(target).abs();

    for (final item in items.skip(1)) {
      final diff = item.time.difference(target).abs();

      if (diff < minDiff) {
        minDiff = diff;
        nearest = item;
      }
    }

    return nearest;
  }
}

class ForecastWeatherItem {
  final DateTime time;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final String icon;

  ForecastWeatherItem({
    required this.time,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
  });

  factory ForecastWeatherItem.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).isNotEmpty
        ? json['weather'][0] as Map<String, dynamic>
        : <String, dynamic>{};

    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};

    final dtTxt = json['dt_txt']?.toString();
    final parsedTime = dtTxt != null
        ? DateTime.tryParse(dtTxt) ?? DateTime.now()
        : DateTime.now();

    return ForecastWeatherItem(
      time: parsedTime,
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      description: weather['description']?.toString() ?? 'Không có dữ liệu',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      icon: weather['icon']?.toString() ?? '01d',
    );
  }
}