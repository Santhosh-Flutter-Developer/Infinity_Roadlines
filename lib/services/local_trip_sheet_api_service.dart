import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_trip_sheet_model.dart';

/// Session helpers for the `tripsheet_type` returned by the login API.
/// Stored in the same SharedPreferences the rest of the auth session uses.
class TripsheetType {
  static const String prefsKey = 'tripsheet_type';
  static const String general = 'general';
  static const String local = 'local';

  /// Anything other than an explicit "local" is treated as "general", so a
  /// missing/unknown value (including sessions saved before this feature
  /// existed) keeps the existing General behaviour.
  static String normalize(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    return value == local ? local : general;
  }

  static Future<bool> isLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return normalize(prefs.getString(prefsKey)) == local;
  }
}

/// Thrown for any Local API failure; [message] is safe to show to the user.
class LocalTripApiException implements Exception {
  final String message;
  LocalTripApiException(this.message);

  @override
  String toString() => message;
}

class LocalTripSheetApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  // static const String _apiBase = 'https://thetransporters.in/api/'; ///LIVE URL
  static const String _apiBase =
      'https://sriseosolutions.com/mahendran/infinity_roadlines/api/'; ///DEV URL

  final String _listUrl = '${_apiBase}get_local_trip_sheet_list.php';
  final String _detailsUrl = '${_apiBase}get_local_trip_sheet_details.php';
  final String _deliveryUrl = '${_apiBase}update_local_lr_delivery.php';
  final String _statusUrl = '${_apiBase}update_local_trip_sheet_status.php';

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('token') ?? '';
    final token =
        saved.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');
    if (token.isEmpty) {
      throw LocalTripApiException('Session expired. Please login again.');
    }
    return token;
  }

  /// The logged-in driver's id: the `user_id` saved at login. Never hardcoded.
  Future<String> _driverId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id') ?? '';
    if (id.isEmpty) {
      throw LocalTripApiException('Session expired. Please login again.');
    }
    return id;
  }

  /// Shared POST + response validation. Returns the decoded JSON map when the
  /// API reports `status == true`; throws [LocalTripApiException] otherwise.
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await _token();
    try {
      final response = await _dio.post(
        url,
        data: {...body, 'token': token},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw LocalTripApiException(
          'The server returned an unexpected response. Please try again.',
        );
      }
      if (data['status'] == true) return data;
      throw LocalTripApiException(
        data['message']?.toString() ?? 'Something went wrong.',
      );
    } on LocalTripApiException {
      rethrow;
    } on DioException catch (e) {
      final errBody = e.response?.data;
      final serverMessage = errBody is Map ? errBody['message']?.toString() : null;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw LocalTripApiException(
            'The connection timed out. Please try again.',
          );
        case DioExceptionType.connectionError:
          throw LocalTripApiException(
            'Network error: Please check your connection.',
          );
        default:
          if (e.response != null) {
            throw LocalTripApiException(
              'Server error: ${serverMessage ?? e.response?.statusCode}',
            );
          }
          throw LocalTripApiException(
            'Network error: Please check your connection.',
          );
      }
    } catch (e) {
      throw LocalTripApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// POST api/get_local_trip_sheet_list.php
  Future<List<LocalTripSheet>> fetchLocalTripSheets({
    String status = 'Dispatched',
    int pageNumber = 1,
    int pageLimit = 20,
  }) async {
    final data = await _post(_listUrl, {
      'driver_id': await _driverId(),
      'status': status,
      'page_number': pageNumber,
      'page_limit': pageLimit,
    });
    final payload = data['data'];
    final list = payload is Map ? payload['list'] : null;
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LocalTripSheet.fromJson)
        .toList();
  }

  /// POST api/get_local_trip_sheet_details.php
  Future<LocalTripSheetDetails> fetchLocalTripSheetDetails({
    required String localTripNumber,
  }) async {
    final data = await _post(_detailsUrl, {
      'local_trip_number': localTripNumber,
    });
    final payload = data['data'];
    if (payload is! Map<String, dynamic>) {
      throw LocalTripApiException('No tripsheet details were returned.');
    }
    return LocalTripSheetDetails.fromJson(payload);
  }

  /// POST api/update_local_lr_delivery.php
  Future<LocalDeliveryResult> updateLocalLrDelivery({
    required String localTripSheetId,
    required String lrId,
    required String receivedPerson,
    required String receivedMobileNumber,
    required String deliveryPin,
    required int pinNotProvided,
    required String paymentMode,
    required String receivedIdentification,
    required double collectedAmount,
  }) async {
    final data = await _post(_deliveryUrl, {
      'local_trip_sheet_id': localTripSheetId,
      'lr_id': lrId,
      'received_person': receivedPerson,
      'received_mobile_number': receivedMobileNumber,
      'delivery_pin': deliveryPin,
      'pin_not_provided': pinNotProvided,
      'payment_mode': paymentMode,
      'received_identification': receivedIdentification,
      'collected_amount': collectedAmount,
    });
    return LocalDeliveryResult.fromJson(data);
  }

  /// POST api/update_local_trip_sheet_status.php
  Future<void> updateLocalTripSheetStatus({
    required String localTripNumber,
    String status = 'Delivered',
  }) async {
    await _post(_statusUrl, {
      'local_trip_number': localTripNumber,
      'status': status,
    });
  }
}
