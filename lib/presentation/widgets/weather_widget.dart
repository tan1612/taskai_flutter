import 'package:flutter/material.dart';
import 'package:taskai/data/models/weather_model.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherModel weather;

  const WeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.95),
              colorScheme.secondary.withOpacity(0.85),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wb_cloudy_rounded,
              size: 52,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.cityName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C • ${weather.description}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Độ ẩm ${weather.humidity}% • Gió ${weather.windSpeed.toStringAsFixed(1)} m/s',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
