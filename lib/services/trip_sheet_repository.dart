import '../models/trip_sheet_model.dart';
import 'trip_sheet_api_service.dart';

class TripSheetRepository {
  final TripSheetApiService _apiService;

  TripSheetRepository(this._apiService);

  Future<List<TripSheetModel>> getTripSheets({
    String fromDate = '',
    String toDate = '',
    String vehicleId = '',
    String destination = '',
    String search = '',
    String filterTripsheet = '',
    int pageNumber = 1,
    int pageLimit = 10,
  }) {
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
}
