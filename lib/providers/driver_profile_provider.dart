import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_profile_model.dart';
import '../services/driver_profile_api_service.dart';

final driverProfileApiProvider = Provider<DriverProfileApiService>((ref) {
  return DriverProfileApiService();
});

class DriverProfileNotifier extends AutoDisposeAsyncNotifier<DriverProfileModel> {
  @override
  FutureOr<DriverProfileModel> build() async {
    // We defer the loading sequence tightly to explicitly requesting ID
    throw Exception('No driver ID provided. Profile uninitialized.');
  }

  Future<void> loadProfile(String driverId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref.read(driverProfileApiProvider).fetchDriverProfile(driverId);
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final driverProfileProvider = AutoDisposeAsyncNotifierProvider<DriverProfileNotifier, DriverProfileModel>(() {
  return DriverProfileNotifier();
});
