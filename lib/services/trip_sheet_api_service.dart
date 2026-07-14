import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_sheet_model.dart';

class TripSheetApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sriseosolutions.com/mahendran/infinity_roadlines/api/get_trip_sheet_list.php';

  Future<List<TripSheetModel>> fetchTripSheets({
    String fromDate = '',
    String toDate = '',
    String vehicleId = '',
    String destination = '',
    String search = '',
    String filterTripsheet = '',
    int pageNumber = 1,
    int pageLimit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token') ?? '';

      final token = savedToken.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');

      if (token.isEmpty) {
        print("Token not found in SharedPreferences");
        throw Exception("Token is required. Please login first.");
      }

      // 6. Print token details
      print("TOKEN LENGTH = ${token.length}");
      print("TOKEN START = ${token.substring(0, 20)}");
      print("TOKEN END = ${token.substring(token.length - 20)}");
      print("TOKEN HAS NEWLINE = ${token.contains('\n')}");
      print("TOKEN HAS CR = ${token.contains('\r')}");
      print("AUTH HEADER = Bearer $token");

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = {
        'from_date': fromDate,
        'to_date': toDate,
        'vehicle_id': vehicleId,
        'destination': destination,
        'search': search,
        'filter_tripsheet': filterTripsheet,
        'page_number': pageNumber,
        'page_limit': pageLimit,
        'token': token, // Providing token directly in the POST body payload for auth.php fallback
      };

      final response = await _dio.post(
        _baseUrl,
        data: body,
        options: Options(
          headers: headers,
        ),
      );

      print("STATUS = ${response.statusCode}");
      print("BODY = ${response.data}");

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == true && data['data'] != null) {
          final listJson = data['data']['list'];
          if (listJson is List) {
            return listJson
                .map((json) => TripSheetModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return [];
        } else {
          throw Exception(data['message'] ?? 'Failed to load trip sheets');
        }
      } else {
        throw Exception('Invalid API response format');
      }
    } on DioException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data?['message'] ?? e.response?.statusCode}');
      } else {
        throw Exception('Network error: Please check your connection.');
      }
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      throw Exception(e.toString());
    }
  }
}
