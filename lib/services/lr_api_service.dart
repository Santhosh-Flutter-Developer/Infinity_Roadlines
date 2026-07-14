import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lr_model.dart';

class LRApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sriseosolutions.com/mahendran/infinity_roadlines/api/get_lr_list.php';

  Future<List<LRModel>> fetchLRList({
    String tripSheetId = '',
    String fromDate = '',
    String toDate = '',
    String consignorId = '',
    String consigneeId = '',
    String status = '',
    String destination = '',
    String search = '',
    int pageNumber = 1,
    int pageLimit = 50,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token') ?? '';
      final token = savedToken.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');

      if (token.isEmpty) {
        throw Exception("Token is required. Please login first.");
      }

      print("--- LR LIST REQUEST ---");
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      final body = {
        'trip_sheet_id': tripSheetId,
        'from_date': fromDate,
        'to_date': toDate,
        'consignor_id': consignorId,
        'consignee_id': consigneeId,
        'status': status,
        'destination': destination,
        'search': search,
        'page_number': pageNumber,
        'page_limit': pageLimit,
        'token': token, // Added fallback
      };

      print("URL: $_baseUrl");
      print("METHOD: POST");
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
                .map((json) => LRModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return [];
        } else {
          throw Exception(data['message'] ?? 'Failed to load LRs');
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
