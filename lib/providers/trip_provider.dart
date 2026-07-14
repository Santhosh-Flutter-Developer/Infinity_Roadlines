import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../models/lr_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

import 'trip_sheet_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return MockFirestoreService();
});

final driverTripsProvider = StreamProvider<List<TripModel>>((ref) {
  final tripSheetsAsync = ref.watch(tripSheetsProvider);
  if (tripSheetsAsync.isLoading) {
    return const Stream.empty();
  }
  if (tripSheetsAsync.hasError) {
    return Stream.error(tripSheetsAsync.error!, tripSheetsAsync.stackTrace!);
  }
  final list = tripSheetsAsync.value ?? [];
  final tripModels = list.map((ts) => ts.toTripModel()).toList();
  return Stream.value(tripModels);
});

final selectedTripIdProvider = StateProvider<String?>((ref) => null);

final selectedTripProvider = Provider<TripModel?>((ref) {
  final trips = ref.watch(driverTripsProvider).value ?? [];
  final selectedId = ref.watch(selectedTripIdProvider);
  if (selectedId == null) return null;
  try {
    return trips.firstWhere((t) => t.tripId == selectedId);
  } catch (_) {
    return null;
  }
});

final selectedTripLRsProvider = StreamProvider<List<LRModel>>((ref) {
  final selectedId = ref.watch(selectedTripIdProvider);
  if (selectedId == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchLRsForTrip(selectedId);
});

final selectedLrIdProvider = StateProvider<String?>((ref) => null);

final selectedLrProvider = Provider<LRModel?>((ref) {
  final lrs = ref.watch(selectedTripLRsProvider).value ?? [];
  final selectedId = ref.watch(selectedLrIdProvider);
  if (selectedId == null) return null;
  try {
    return lrs.firstWhere((lr) => lr.lrId == selectedId);
  } catch (_) {
    return null;
  }
});

final adminDriversProvider = StreamProvider<List<UserModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchAllDrivers();
});
