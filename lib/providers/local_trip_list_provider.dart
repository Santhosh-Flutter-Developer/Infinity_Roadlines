import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_trip_sheet_model.dart';
import '../models/trip_model.dart';
import '../services/local_trip_sheet_api_service.dart';
import 'lr_provider.dart' show localTripSheetApiServiceProvider;

/// Records requested per page for the Local tripsheet lists.
const int localTripPageLimit = 20;

const String localStatusDispatched = 'Dispatched';
const String localStatusCompleted = 'Completed';

class LocalTripListState {
  final List<TripModel> items;

  /// First load / refresh while nothing is on screen yet.
  final bool isLoading;
  final bool isLoadingMore;

  /// Error of the first page (shown full-screen only when [items] is empty).
  final String? error;

  /// Error of a "next page" request (shown as a retry row under the list).
  final String? loadMoreError;
  final int page;
  final bool hasMore;

  const LocalTripListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
    this.page = 0,
    this.hasMore = false,
  });

  LocalTripListState copyWith({
    List<TripModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? page,
    bool? hasMore,
  }) {
    return LocalTripListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class LocalTripListNotifier extends StateNotifier<LocalTripListState> {
  final LocalTripSheetApiService _api;
  final String status;

  /// Bumped on every refresh so a slow, outdated response can never overwrite
  /// newer data.
  int _generation = 0;

  /// A refresh is already running (e.g. the initial load) -> ignore duplicates
  /// such as a tab tap landing at the same moment.
  bool _refreshInFlight = false;

  LocalTripListNotifier(this._api, this.status)
      : super(const LocalTripListState(isLoading: true));

  Future<List<TripModel>> _toTrips(List<LocalTripSheet> sheets) async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('user_id') ?? '';
    return sheets
        .map((t) => t.toTripSheetModel(driverId: driverId).toTripModel())
        .toList();
  }

  /// Uses `total_pages` when the API sends it, otherwise "a full page means
  /// there may be more". An empty page always means the end.
  bool _hasMore(LocalTripSheetPage result, int page) {
    if (result.items.isEmpty) return false;
    if (result.totalPages > 0) return page < result.totalPages;
    return result.items.length >= localTripPageLimit;
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Reloads page 1. Returns an error message on failure, otherwise null.
  Future<String?> refresh() async {
    if (!mounted || _refreshInFlight) return null;
    _refreshInFlight = true;
    final gen = ++_generation;
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isLoadingMore: false,
      clearError: true,
      clearLoadMoreError: true,
    );
    try {
      final result = await _api.fetchLocalTripSheetPage(
        status: status,
        pageNumber: 1,
        pageLimit: localTripPageLimit,
      );
      final trips = await _toTrips(result.items);
      if (!mounted || gen != _generation) return null;
      state = LocalTripListState(
        items: trips,
        page: 1,
        hasMore: _hasMore(result, 1),
      );
      return null;
    } catch (e) {
      if (!mounted || gen != _generation) return null;
      final message = _message(e);
      state = state.copyWith(isLoading: false, error: message);
      return message;
    } finally {
      _refreshInFlight = false;
    }
  }

  /// Loads the next page (called when the list is scrolled to its end).
  /// [retry] is used by the "Retry" row after a failed page request.
  Future<void> loadMore({bool retry = false}) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.error != null) return;
    if (state.loadMoreError != null && !retry) return;

    final gen = _generation;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    try {
      final result = await _api.fetchLocalTripSheetPage(
        status: status,
        pageNumber: nextPage,
        pageLimit: localTripPageLimit,
      );
      final trips = await _toTrips(result.items);
      if (!mounted || gen != _generation) return;

      // Never show the same tripsheet twice if pages overlap.
      final existing = state.items.map((t) => t.tripId).toSet();
      final merged = [
        ...state.items,
        ...trips.where((t) => !existing.contains(t.tripId)),
      ];
      state = state.copyWith(
        items: merged,
        page: nextPage,
        isLoadingMore: false,
        hasMore: _hasMore(result, nextPage),
      );
    } catch (e) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: _message(e));
    }
  }
}

/// One paged list per status ("Dispatched" / "Completed"). `autoDispose`, so
/// leaving the home screen drops the data and it is reloaded fresh on return
/// (same as the General list) and never leaks between logins.
final localTripListProvider = StateNotifierProvider.autoDispose
    .family<LocalTripListNotifier, LocalTripListState, String>((ref, status) {
  final notifier =
      LocalTripListNotifier(ref.watch(localTripSheetApiServiceProvider), status);
  // Load as soon as the list is created. Invalidating the provider (e.g. after
  // an LR is delivered) therefore reloads it automatically.
  Future.microtask(notifier.refresh);
  return notifier;
});