import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_sheet_model.dart';
import '../services/trip_sheet_api_service.dart';
import '../services/trip_sheet_repository.dart';

final tripSheetApiServiceProvider = Provider<TripSheetApiService>((ref) {
  return TripSheetApiService();
});

final tripSheetRepositoryProvider = Provider<TripSheetRepository>((ref) {
  final apiService = ref.watch(tripSheetApiServiceProvider);
  return TripSheetRepository(apiService);
});

class TripSheetNotifier extends StateNotifier<AsyncValue<List<TripSheetModel>>> {
  final TripSheetRepository _repository;

  TripSheetNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchTripSheets();
  }

  Future<void> fetchTripSheets() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getTripSheets(
        fromDate: '',
        toDate: '',
        vehicleId: '',
        destination: '',
        search: '',
        filterTripsheet: '',
        pageNumber: 1,
        pageLimit: 50,
      );
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final tripSheetsProvider = StateNotifierProvider<TripSheetNotifier, AsyncValue<List<TripSheetModel>>>((ref) {
  final repository = ref.watch(tripSheetRepositoryProvider);
  return TripSheetNotifier(repository);
});
