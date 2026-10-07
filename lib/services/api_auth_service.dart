import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'auth_exceptions.dart';
import 'device_id_service.dart';

class ApiAuthService implements AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  ApiAuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final name = prefs.getString('name') ?? 'Driver';
    final role = prefs.getString('role') ?? 'driver';
    if (userId != null) {
      _currentUser = UserModel(
        uid: userId,
        role: role,
        name: name,
        username: prefs.getString('username') ?? '',
        phone: '',
        status: 'online',
        battery: 100.0,
        internetConnected: true,
      );
    }
    _authStateController.add(_currentUser);
  }

  @override
  Future<UserModel?> login(String username, String password) async {
    late final String deviceId;
    try {
      deviceId = await DeviceIdService.getDeviceId();
    } catch (_) {
      // Device id storage failed (rare). Login can't proceed safely
      // without it since the backend expects it on every request.
      throw const UnknownAuthException(
        'Could not prepare this device for login. Please restart the app and try again.',
      );
    }

    try {
      final response = await _dio.post(
        // 'https://thetransporters.in/api/login.php', ///LIVE URL
        "https://sriseosolutions.com/mahendran/infinity_roadlines/api/login.php", ///DEV URL
        data: {
          'username': username,
          'password': password,
          'device_id': deviceId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } on FormatException {
          throw ServerException(
            'The server returned an unexpected response. Please try again later.',
            statusCode: response.statusCode,
          );
        }
      }

      if (data is! Map<String, dynamic>) {
        throw ServerException(
          'The server returned an unexpected response. Please try again later.',
          statusCode: response.statusCode,
        );
      }

      if (data['status'] == true) {
        final responseData = data['data'];
        if (responseData == null) {
          throw ServerException(
            data['message']?.toString() ?? 'Login failed. Please try again.',
            statusCode: response.statusCode,
          );
        }

        final userId = responseData['user_id']?.toString() ?? '';
        final name = responseData['user_name']?.toString() ?? 'Driver';
        final loginId = responseData['login_id']?.toString() ?? username;
        final userMobile = responseData['user_mobile']?.toString() ?? '';
        final roleName = responseData['role_name']?.toString() ?? 'Driver';
        final token = responseData['token']?.toString() ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('name', name);
        await prefs.setString('username', loginId);
        await prefs.setString('token', token);
        await prefs.setString('role', roleName.toLowerCase());
        _currentUser = UserModel(
          uid: userId,
          role: roleName.toLowerCase(),
          name: name,
          username: loginId,
          phone: userMobile,
          status: 'online',
          battery: 100.0,
          internetConnected: true,
        );
        _authStateController.add(_currentUser);
        return _currentUser;
      }

      // status == false, or missing entirely -> treat as a rejected login.
      final message = data['message']?.toString();
      final reason = (data['reason'] ?? data['error_code'])?.toString().toLowerCase();
      final lowerMsg = message?.toLowerCase() ?? '';
      final isDeviceIssue = reason == 'device_not_authorized' ||
          reason == 'device_mismatch' ||
          lowerMsg.contains('device');
      if (isDeviceIssue) {
        throw DeviceNotAuthorizedException(
          message ?? 'This device is not authorized for this account.',
        );
      }
      throw InvalidCredentialsException(
        message ?? 'Invalid username or password.',
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  AuthException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'The connection timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Please check your internet connection and try again.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Could not establish a secure connection. Please try again.',
        );
      case DioExceptionType.cancel:
        return const UnknownAuthException('Login was cancelled.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String? serverMessage;
        final body = e.response?.data;
        try {
          final parsed = body is String ? jsonDecode(body) : body;
          if (parsed is Map<String, dynamic>) {
            serverMessage = parsed['message']?.toString();
          }
        } catch (_) {
          // ignore parse failures, fall back below
        }

        if (statusCode == 401 || statusCode == 403) {
          return InvalidCredentialsException(
            serverMessage ?? 'Invalid username or password.',
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            serverMessage ?? 'Server error. Please try again later.',
            statusCode: statusCode,
          );
        }
        return ServerException(
          serverMessage ?? 'Login failed (error $statusCode). Please try again.',
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const NetworkException(
            'Please check your internet connection and try again.',
          );
        }
        return NetworkException(e.message ?? 'Network error. Please try again.');
      default:
        // Covers newer DioExceptionType values (e.g. transformTimeout)
        // added in later dio versions that aren't explicitly handled above.
        return UnknownAuthException(e.message ?? 'Something went wrong. Please try again.');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('name');
    await prefs.remove('username');
    await prefs.remove('role');
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
}