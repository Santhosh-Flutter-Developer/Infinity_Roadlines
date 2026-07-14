import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_card_model.dart';

class TripCardApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sriseosolutions.com/mahendran/infinity_roadlines/api/get_trip_card_list.php';

  Future<List<TripCardModel>> fetchTripCards({
    String fromDate = '',
    String toDate = '',
    String vehicleId = '',
    String driverId = '',
    int pageNumber = 1,
    int pageLimit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token') ?? '';
      final token = savedToken.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');

      if (token.isEmpty) {
        throw Exception("Token is required. Please login first.");
      }

      print("--- TRIP CARD REQUEST ---");
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      final body = {
        'from_date': fromDate,
        'to_date': toDate,
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'page_number': pageNumber,
        'page_limit': pageLimit,
        'token': token,
      };

      print("URL: $_baseUrl");
      print("Headers: $headers");
      print("Body: $body");

      final response = await _dio.post(
        _baseUrl,
        data: body,
        options: Options(headers: headers),
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.data}");

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == true && data['data'] != null) {
          final listJson = data['data']['list'];
          if (listJson is List) {
            return listJson
                .map((json) => TripCardModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return [];
        } else {
          throw Exception(data['message'] ?? 'Failed to load trip cards');
        }
      } else {
        throw Exception('Invalid API response format');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data?['message'] ?? e.response?.statusCode}');
      }
      throw Exception('Network error: Please check your connection.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
