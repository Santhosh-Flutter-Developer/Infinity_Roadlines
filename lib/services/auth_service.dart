import 'dart:async';
import '../models/user_model.dart';
import 'mock_database.dart';

abstract class AuthService {
  Future<UserModel?> login(String username, String password);
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Stream<UserModel?> get authStateChanges;
}

class MockAuthService implements AuthService {
  final MockDatabase _db = MockDatabase();
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  MockAuthService() {
    _authStateController.add(null);
  }

  @override
  Future<UserModel?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _db.authenticate(username, password);
    if (user != null) {
      _currentUser = user;
      _authStateController.add(_currentUser);
      _db.updateUserStatus(user.uid, 'online');
    }
    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    if (_currentUser != null) {
      _db.updateUserStatus(_currentUser!.uid, 'offline');
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
}
