import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_card_model.dart';
import '../services/trip_card_api_service.dart';

final tripCardApiServiceProvider = Provider<TripCardApiService>((ref) {
  return TripCardApiService();
});

class TripCardsNotifier extends AsyncNotifier<List<TripCardModel>> {
  @override
  FutureOr<List<TripCardModel>> build() async {
    return [];
  }

  Future<void> fetchTripCards() async {
    state = const AsyncValue.loading();
    try {
      final tripCards = await ref.read(tripCardApiServiceProvider).fetchTripCards();
      state = AsyncValue.data(tripCards);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final tripCardsProvider = AsyncNotifierProvider<TripCardsNotifier, List<TripCardModel>>(() {
  return TripCardsNotifier();
});

final driverTripCardsProvider = StreamProvider<List<TripCardModel>>((ref) {
  final asyncState = ref.watch(tripCardsProvider);
  if (asyncState.isLoading) {
    return const Stream.empty();
  }
  if (asyncState.hasError) {
    return Stream.error(asyncState.error!, asyncState.stackTrace!);
  }
  return Stream.value(asyncState.value ?? []);
});
