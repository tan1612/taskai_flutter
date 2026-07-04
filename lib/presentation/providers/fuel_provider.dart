import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/data/models/fuel_price_model.dart';
import 'package:taskai/data/repositories/fuel_price_repository.dart';
import 'package:taskai/presentation/providers/app_providers.dart';

class FuelPriceService {
  final FuelPriceModel _prices;

  FuelPriceService(this._prices);

  double getFuelPriceForType(String fuelType) {
    final normalised = fuelType.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (normalised.contains('ron95')) {
      return _prices.ron95;
    } else if (normalised.contains('ron92') || normalised.contains('e5')) {
      return _prices.e5Ron92;
    } else if (normalised.contains('diesel') || normalised.contains('dau') || normalised.contains('dầu')) {
      return _prices.diesel;
    }
    return 20000.0; // fallback default price
  }

  double calculateFuelCost({
    required double estimatedKm,
    required double consumptionLPer100Km,
    required String fuelType,
  }) {
    final price = getFuelPriceForType(fuelType);
    return estimatedKm * consumptionLPer100Km / 100 * price;
  }
}

class FuelPriceNotifier extends StateNotifier<FuelPriceModel> {
  final FuelPriceRepository repository;

  FuelPriceNotifier(this.repository) : super(repository.getPrices());

  Future<void> updatePrices({
    required double ron95,
    required double e5Ron92,
    required double diesel,
    required String source,
  }) async {
    final updated = FuelPriceModel(
      ron95: ron95,
      e5Ron92: e5Ron92,
      diesel: diesel,
      unit: 'VND',
      source: source,
      updatedAt: DateTime.now(),
    );
    await repository.savePrices(updated);
    state = updated;
  }

  FuelPriceService getService() {
    return FuelPriceService(state);
  }
}

final fuelPriceProvider = StateNotifierProvider<FuelPriceNotifier, FuelPriceModel>((ref) {
  final repo = ref.read(fuelPriceRepositoryProvider);
  return FuelPriceNotifier(repo);
});
