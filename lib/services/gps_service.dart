import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:battery_plus/battery_plus.dart';

class PositionData {
  final double latitude;
  final double longitude;
  final double speed;
  final double battery;
  final DateTime timestamp;

  PositionData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.battery,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'battery': battery,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PositionData.fromJson(Map<String, dynamic> map) {
    return PositionData(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      speed: map['speed'] ?? 0.0,
      battery: map['battery'] ?? 100.0,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}

abstract class GpsService {
  Future<bool> isServiceEnabled();
  Future<bool> requestPermissions();
  Stream<PositionData> get locationStream;
  Future<PositionData> getCurrentLocation();
}

class RealGpsService implements GpsService {
  static final RealGpsService _instance = RealGpsService._internal();
  factory RealGpsService() => _instance;
  RealGpsService._internal();

  final Battery _battery = Battery();

  @override
  Future<bool> isServiceEnabled() async {
    return await gl.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    debugPrint('[GPS AUTH] Checking LocationPermissions via Geolocator wrapper...');
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      debugPrint('[GPS AUTH] LocationPermission initially denied. Requesting explicitly.');
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        debugPrint('[GPS AUTH] LocationPermission denied again following prompt constraints.');
        return false;
      }
    }
    
    if (permission == gl.LocationPermission.deniedForever) {
      debugPrint('[GPS AUTH] LocationPermission is PERMANENTLY DENIED. Manual OS Settings configurations required.');
      return false;
    }
    debugPrint('[GPS AUTH] Permissions granted natively parsing streams.');
    return true;
  }

  @override
  Stream<PositionData> get locationStream {
    const locationSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    return gl.Geolocator.getPositionStream(locationSettings: locationSettings).asyncMap((pos) async {
      double batteryLvl = 100.0;
      try {
        batteryLvl = (await _battery.batteryLevel).toDouble();
      } catch (e) {
        debugPrint("Battery read failed: $e");
      }
      return PositionData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speed: pos.speed,
        battery: batteryLvl,
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Future<PositionData> getCurrentLocation() async {
    final pos = await gl.Geolocator.getCurrentPosition(
      desiredAccuracy: gl.LocationAccuracy.high
    );
    double batteryLvl = 100.0;
    try {
      batteryLvl = (await _battery.batteryLevel).toDouble();
    } catch (e) {}

    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      speed: pos.speed,
      battery: batteryLvl,
      timestamp: DateTime.now(),
    );
  }
}
