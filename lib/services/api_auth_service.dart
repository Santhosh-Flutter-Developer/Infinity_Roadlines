import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiAuthService implements AuthService {
  final Dio _dio = Dio();
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
    try {
      final response = await _dio.post(
        'https://sriseosolutions.com/mahendran/infinity_roadlines/api/login.php',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('response.statusCode: ${response.statusCode}');
      print('response.body: ${response.data}');

      var data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        if (data['status'] == true) {
          final responseData = data['data'];
          if (responseData != null) {
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
          } else {
            throw Exception(data['message'] ?? 'Login failed');
          }
        } else if (data['status'] == false) {
          throw Exception(data['message'] ?? 'Login failed');
        } else {
          throw Exception('Invalid API response format. Status: ${response.statusCode}, Body: ${response.data}');
        }
      } else {
        throw Exception('Invalid API response format. Status: ${response.statusCode}, Body: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
         throw Exception('Server error: ${e.response?.statusCode}');
      } else {
         throw Exception('Network error: Please check your connection.');
      }
    } catch (e) {
      throw Exception(e.toString());
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
