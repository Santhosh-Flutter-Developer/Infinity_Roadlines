import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_trip_sheet_model.dart';
import '../models/trip_model.dart';
import '../services/local_trip_sheet_api_service.dart';
import '../services/trip_sheet_api_service.dart';
import 'lr_provider.dart' show localTripSheetApiServiceProvider;
import 'trip_sheet_provider.dart' show tripSheetApiServiceProvider;

/// Records requested per page for the tripsheet lists (Local and General).
const int tripPageLimit = 20;

const String tripStatusDispatched = 'Dispatched';
const String tripStatusCompleted = 'Completed';

/// One page of tripsheets, already mapped to the card model.
class TripListPage {
  final List<TripModel> items;

  /// Rows the API returned for this page (before any client-side filtering).
  final int rawCount;

  /// 0 when the API does not report `total_pages`.
  final int totalPages;

  TripListPage({
    required this.items,
    required this.rawCount,
    this.totalPages = 0,
  });
}

typedef TripPageFetcher = Future<TripListPage> Function(
  String status,
  int page,
  int limit,
);

class TripListState {
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

  const TripListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
    this.page = 0,
    this.hasMore = false,
  });

  TripListState copyWith({
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
    return TripListState(
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

class TripListNotifier extends StateNotifier<TripListState> {
  final TripPageFetcher _fetch;
  final String status;

  /// Bumped on every refresh so a slow, outdated response can never overwrite
  /// newer data.
  int _generation = 0;

  /// A refresh is already running (e.g. the initial load) -> ignore duplicates
  /// such as a tab tap landing at the same moment.
  bool _refreshInFlight = false;

  TripListNotifier(this._fetch, this.status)
      : super(const TripListState(isLoading: true));

  /// Uses `total_pages` when the API sends it, otherwise "a full page means
  /// there may be more". An empty page always means the end.
  bool _hasMore(TripListPage result, int page) {
    if (result.rawCount == 0) return false;
    if (result.totalPages > 0) return page < result.totalPages;
    return result.rawCount >= tripPageLimit;
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
      final result = await _fetch(status, 1, tripPageLimit);
      final trips = result.items;
      if (!mounted || gen != _generation) return null;
      state = TripListState(
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
      final result = await _fetch(status, nextPage, tripPageLimit);
      final trips = result.items;
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

/// Local drivers: get_local_trip_sheet_list.php (`status` = Dispatched/Completed).
Future<TripListPage> _fetchLocalPage(
  LocalTripSheetApiService api,
  String status,
  int page,
  int limit,
) async {
  final prefs = await SharedPreferences.getInstance();
  final driverId = prefs.getString('user_id') ?? '';
  final result = await api.fetchLocalTripSheetPage(
    status: status,
    pageNumber: page,
    pageLimit: limit,
  );
  return TripListPage(
    items: result.items
        .map((t) => t.toTripSheetModel(driverId: driverId).toTripModel())
        .toList(),
    rawCount: result.items.length,
    totalPages: result.totalPages,
  );
}

/// Which tab a General tripsheet belongs to: "Completed" tab = completed,
/// everything else is still in progress = "Dispatched" tab.
bool _belongsToTab(String tripStatus, String tab) {
  final completed = tripStatus.trim().toLowerCase() == 'completed';
  return tab == tripStatusCompleted ? completed : !completed;
}

/// General drivers: get_trip_sheet_list.php with `status` = tab status
/// (same key as the Local API). Rows that don't belong to the tab are dropped as a safety net in
/// case the server ignores the filter.
Future<TripListPage> _fetchGeneralPage(
  TripSheetApiService api,
  String status,
  int page,
  int limit,
) async {
  final list = await api.fetchTripSheets(
    status: status,
    pageNumber: page,
    pageLimit: limit,
  );
  return TripListPage(
    items: list
        .map((t) => t.toTripModel())
        .where((t) => _belongsToTab(t.status, status))
        .toList(),
    rawCount: list.length,
  );
}

/// One paged list per status ("Dispatched" / "Completed"). `autoDispose`, so
/// leaving the home screen drops the data and it is reloaded fresh on return
/// and never leaks between logins. The list loads as soon as it is created, so
/// invalidating the provider reloads it.
final localTripListProvider = StateNotifierProvider.autoDispose
    .family<TripListNotifier, TripListState, String>((ref, status) {
  final api = ref.watch(localTripSheetApiServiceProvider);
  final notifier = TripListNotifier(
    (st, page, limit) => _fetchLocalPage(api, st, page, limit),
    status,
  );
  Future.microtask(notifier.refresh);
  return notifier;
});

final generalTripListProvider = StateNotifierProvider.autoDispose
    .family<TripListNotifier, TripListState, String>((ref, status) {
  final api = ref.watch(tripSheetApiServiceProvider);
  final notifier = TripListNotifier(
    (st, page, limit) => _fetchGeneralPage(api, st, page, limit),
    status,
  );
  Future.microtask(notifier.refresh);
  return notifier;
});