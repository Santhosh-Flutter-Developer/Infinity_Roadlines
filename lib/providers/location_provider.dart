import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../services/gps_service.dart';
import 'auth_provider.dart';
import 'trip_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return RealGpsService();
});

final isGpsEnabledProvider = StateProvider<bool>((ref) => true);

final driverCurrentLocationProvider = StateProvider<PositionData?>((ref) => null);

class DriverLocationNotifier {
  final Ref _ref;
  StreamSubscription<PositionData>? _sub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final Dio _dio = Dio();
  
  DriverLocationNotifier(this._ref) {
    _init();
  }

  void _init() async {
    final gps = _ref.read(gpsServiceProvider);
    
    _ref.read(isGpsEnabledProvider.notifier).state = await gps.isServiceEnabled();

    _sub = gps.locationStream.listen((pos) async {
      _ref.read(isGpsEnabledProvider.notifier).state = true;
      _ref.read(driverCurrentLocationProvider.notifier).state = pos;
      await _queueLocationUpdate(pos);
    }, onError: (e) async {
      final isEnabled = await gps.isServiceEnabled();
      _ref.read(isGpsEnabledProvider.notifier).state = isEnabled;
    });

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _syncQueuedLocations();
      }
    });
  }

  Future<void> _queueLocationUpdate(PositionData pos) async {
    final user = _ref.read(authStateProvider).value;
    final tripSheetId = _ref.read(selectedTripIdProvider) ?? "";
    
    if (user != null && user.role == 'driver') {
      final payload = {
        "driver_id": user.uid,
        "trip_sheet_id": tripSheetId,
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "speed": pos.speed,
        "battery": pos.battery,
        "timestamp": pos.timestamp.toIso8601String()
      };

      final conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) {
        await _saveToLocalQueue(payload);
      } else {
        await _sendToBackend(payload);
        await _syncQueuedLocations(); 
      }
    }
  }

  Future<void> _saveToLocalQueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getStringList('offline_locations') ?? [];
    queueStr.add(jsonEncode(payload));
    await prefs.setStringList('offline_locations', queueStr);
  }

  Future<void> _syncQueuedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getStringList('offline_locations') ?? [];
    
    if (queueStr.isEmpty) return;

    List<String> failedQueueStr = [];

    for (String itemStr in queueStr) {
      try {
        final payload = jsonDecode(itemStr);
        await _sendToBackend(payload, isRetry: true);
      } catch (e) {
        failedQueueStr.add(itemStr);
      }
    }
    await prefs.setStringList('offline_locations', failedQueueStr);
  }

  Future<void> _sendToBackend(Map<String, dynamic> payload, {bool isRetry = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token') ?? '';
    final token = savedToken.trim().replaceAll('\n', '').replaceAll('\r', '').replaceAll('"', '');
    
    payload['token'] = token;
    
    try {
      await _dio.post(
        'https://sriseosolutions.com/mahendran/infinity_roadlines/api/update_driver_location.php',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
      );
    } catch (e) {
      if (!isRetry) {
        await _saveToLocalQueue(payload);
      } else {
        rethrow;
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
  }
}

final driverLocationNotifierProvider = Provider<DriverLocationNotifier>((ref) {
  final notifier = DriverLocationNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
