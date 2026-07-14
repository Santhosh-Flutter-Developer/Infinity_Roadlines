import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_profile_model.dart';

class DriverProfileApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sriseosolutions.com/mahendran/infinity_roadlines/api/get_driver_profile.php';

  Future<DriverProfileModel> fetchDriverProfile(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token') ?? '';
      final token = savedToken.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');

      if (token.isEmpty) {
        throw Exception("Authentication Token is missing.");
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      final body = {
        'driver_id': driverId,
        'token': token, 
      };

      final response = await _dio.post(
        _baseUrl,
        data: body,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == true && data['data'] != null) {
          return DriverProfileModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load profile');
        }
      } else {
        throw Exception('Invalid API response structure');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data?['message'] ?? e.response?.statusCode}');
      }
      throw Exception('Network error: Unable to reach the server.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
