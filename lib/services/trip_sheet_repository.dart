import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_sheet_model.dart';
import 'local_trip_sheet_api_service.dart';
import 'trip_sheet_api_service.dart';

class TripSheetRepository {
  final TripSheetApiService _apiService;
  final LocalTripSheetApiService _localApiService;

  TripSheetRepository(this._apiService, [LocalTripSheetApiService? localApiService])
      : _localApiService = localApiService ?? LocalTripSheetApiService();

  Future<List<TripSheetModel>> getTripSheets({
    String fromDate = '',
    String toDate = '',
    String vehicleId = '',
    String destination = '',
    String search = '',
    String filterTripsheet = '',
    int pageNumber = 1,
    int pageLimit = 10,
  }) async {
    // tripsheet_type == "local" -> Local API, mapped onto the same model the
    // existing Tripsheet UI already renders. Otherwise: unchanged General flow.
    if (await TripsheetType.isLocal()) {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('user_id') ?? '';
      final localList = await _localApiService.fetchLocalTripSheets(
        status: 'Dispatched',
        pageNumber: pageNumber,
        pageLimit: pageLimit,
      );
      return localList
          .map((t) => t.toTripSheetModel(driverId: driverId))
          .toList();
    }
    return _apiService.fetchTripSheets(
      fromDate: fromDate,
      toDate: toDate,
      vehicleId: vehicleId,
      destination: destination,
      search: search,
      filterTripsheet: filterTripsheet,
      pageNumber: pageNumber,
      pageLimit: pageLimit,
    );
  }

  Future<bool> acknowledgeTrip({
    required String tripSheetId,
    required String status,
  }) {
    return _apiService.acknowledgeTrip(tripSheetId: tripSheetId, status: status);
  }
}