import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lr_model.dart';
import '../models/local_trip_sheet_model.dart';
import '../services/lr_api_service.dart';
import '../services/local_trip_sheet_api_service.dart';

final lrApiServiceProvider = Provider<LRApiService>((ref) {
  return LRApiService();
});

final localTripSheetApiServiceProvider = Provider<LocalTripSheetApiService>((ref) {
  return LocalTripSheetApiService();
});

/// Header/counts of the Local tripsheet currently open in the LR list
/// (null for General). Counts are kept in sync after each delivery.
final localTripSheetDetailsProvider = StateProvider<LocalTripSheetDetails?>((ref) => null);

class LRListNotifier extends AsyncNotifier<List<LRModel>> {
  final Set<String> _locallyDeliveredIds = {}; // Local memory cache for optimistic updates

  // ---- Local Tripsheet state ----
  String _localTripNumber = '';
  final Set<String> _deliveringLocalLrs = {}; // guards against double submits

  @override
  FutureOr<List<LRModel>> build() async {
    return [];
  }

  Future<void> fetchLRs({
    String tripSheetId = '',
    String fromDate = '',
    String toDate = '',
    String consignorId = '',
    String consigneeId = '',
    String status = '',
    String destination = '',
    String search = '',
    int pageNumber = 1,
    int pageLimit = 50,
  }) async {
    state = const AsyncValue.loading();

    // tripsheet_type == "local": `tripSheetId` is the local_trip_number.
    if (await TripsheetType.isLocal()) {
      await _fetchLocalLRs(tripSheetId);
      return;
    }

    try {
      final lrs = await ref.read(lrApiServiceProvider).fetchLRList(
            tripSheetId: tripSheetId,
            fromDate: fromDate,
            toDate: toDate,
            consignorId: consignorId,
            consigneeId: consigneeId,
            status: status,
            destination: destination,
            search: search,
            pageNumber: pageNumber,
            pageLimit: pageLimit,
          );
          
      // Ensure locally marked LRs retain their 'Delivered' status across API re-fetches
      final mappedLrs = lrs.map((lr) {
        if (_locallyDeliveredIds.contains(lr.lrId)) {
          return LRModel(
            lrId: lr.lrId,
            lrNumber: lr.lrNumber,
            entryDate: lr.entryDate,
            consignorId: lr.consignorId,
            consignorName: lr.consignorName,
            consigneeId: lr.consigneeId,
            consigneeName: lr.consigneeName,
            fromBranchId: lr.fromBranchId,
            fromBranch: lr.fromBranch,
            toBranchId: lr.toBranchId,
            toBranch: lr.toBranch,
            quantity: lr.quantity,
            unitName: lr.unitName,
            amount: lr.amount,
            status: 'Delivered', // Safe copy fallback
            billType: lr.billType,
          );
        }
        return lr;
      }).toList();

      state = AsyncValue.data(mappedLrs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // ===========================================================================
  // Local Tripsheet support
  // ===========================================================================

  Future<void> _fetchLocalLRs(String localTripNumber) async {
    _localTripNumber = localTripNumber;
    try {
      final details = await ref
          .read(localTripSheetApiServiceProvider)
          .fetchLocalTripSheetDetails(localTripNumber: localTripNumber);
      ref.read(localTripSheetDetailsProvider.notifier).state = details;
      state = AsyncValue.data(details.lrs.map((l) => l.toLRModel()).toList());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Full Local delivery sequence:
  ///   1. update_local_lr_delivery.php (throws on failure; nothing is marked
  ///      delivered locally until it succeeds)
  ///   2. mark the LR Delivered in state + update counts
  ///   3. only if `all_lrs_delivered == true`: update_local_trip_sheet_status.php
  ///
  /// A failure in step 3 does NOT fail the delivery: it is reported through
  /// [LocalDeliveryOutcome.tripStatusError] and can be retried with
  /// [retryLocalTripStatus] without re-calling the LR delivery API.
  Future<LocalDeliveryOutcome> deliverLocalLR({
    required LRModel lr,
    required String receivedPerson,
  }) async {
    // Re-entrancy guard (double tap / rebuild).
    if (!_deliveringLocalLrs.add(lr.lrId)) {
      throw LocalTripApiException('Delivery is already in progress.');
    }
    final api = ref.read(localTripSheetApiServiceProvider);
    final person = receivedPerson.trim();
    try {
      final result = await api.updateLocalLrDelivery(
        localTripSheetId: _localTripNumber,
        lrId: lr.lrNumber,
        receivedPerson: person,
        receivedMobileNumber: lr.receivedMobileNumber.isNotEmpty
            ? lr.receivedMobileNumber
            : lr.consigneePhone,
        deliveryPin: lr.deliveryPin,
        pinNotProvided: lr.pinNotProvided,
        paymentMode: lr.paymentMode,
        receivedIdentification: lr.receivedIdentification.isNotEmpty
            ? lr.receivedIdentification
            : '$person Signed',
        collectedAmount: lr.collectableAmount,
      );

      // Delivery API succeeded -> now (and only now) update local state.
      _markLocalLrDelivered(lr.lrId);

      String? tripStatusError;
      var tripMarked = false;
      if (result.allLrsDelivered) {
        try {
          await api.updateLocalTripSheetStatus(localTripNumber: _localTripNumber);
          tripMarked = true;
        } catch (e) {
          tripStatusError = e.toString().replaceFirst('Exception: ', '');
        }
      }
      return LocalDeliveryOutcome(
        result: result,
        tripSheetMarkedDelivered: tripMarked,
        tripStatusError: tripStatusError,
      );
    } finally {
      _deliveringLocalLrs.remove(lr.lrId);
    }
  }

  /// Retries only the tripsheet status call (never the LR delivery call).
  /// Returns null on success, or an error message.
  Future<String?> retryLocalTripStatus() async {
    try {
      await ref
          .read(localTripSheetApiServiceProvider)
          .updateLocalTripSheetStatus(localTripNumber: _localTripNumber);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Applies a payment the backend has confirmed (`is_paid == true`) to the LR
  /// right away, then refreshes the tripsheet details in the background so the
  /// backend (e.g. `total_topay_pending`) stays authoritative. Never touches the
  /// delivery status: Paid != Delivered.
  void applyLocalPayment(String lrId, LocalPaymentResult result) {
    final current = state;
    if (current is AsyncData<List<LRModel>>) {
      state = AsyncValue.data(
        current.value
            .map((l) => l.lrId == lrId
                ? l.copyWith(
                    paymentStatus: 'Paid',
                    paymentMode:
                        result.paymentMode.isNotEmpty ? result.paymentMode : null,
                    razorpayPaymentId: result.razorpayPaymentId.isNotEmpty
                        ? result.razorpayPaymentId
                        : null,
                  )
                : l)
            .toList(),
      );
    }
    _refreshLocalDetailsSilently();
  }

  /// Best-effort background refresh (no loading state, errors ignored). If the
  /// server hasn't caught up with a just-confirmed payment/delivery, the
  /// confirmed local value is kept.
  Future<void> _refreshLocalDetailsSilently() async {
    final trip = _localTripNumber;
    if (trip.isEmpty) return;
    try {
      final details = await ref
          .read(localTripSheetApiServiceProvider)
          .fetchLocalTripSheetDetails(localTripNumber: trip);
      if (trip != _localTripNumber) return; // user opened another tripsheet

      ref.read(localTripSheetDetailsProvider.notifier).state = details;

      final current = state;
      if (current is! AsyncData<List<LRModel>>) return;
      final mine = {for (final l in current.value) l.lrId: l};
      final merged = details.lrs.map((server) {
        var lr = server.toLRModel();
        final local = mine[lr.lrId];
        if (local != null) {
          if (local.isPaid && !lr.isPaid) {
            lr = lr.copyWith(
              paymentStatus: local.paymentStatus,
              paymentMode: local.paymentMode,
              razorpayPaymentId: local.razorpayPaymentId,
            );
          }
          if (local.status.toLowerCase() == 'delivered' &&
              lr.status.toLowerCase() != 'delivered') {
            lr = lr.copyWith(
              status: local.status,
              deliveryStatus: local.deliveryStatus,
            );
          }
        }
        return lr;
      }).toList();
      state = AsyncValue.data(merged);
    } catch (_) {
      // Keep what is on screen; the next manual refresh will resync.
    }
  }

  void _markLocalLrDelivered(String lrId) {
    final current = state;
    if (current is! AsyncData<List<LRModel>>) return;
    final updated = current.value
        .map((l) => l.lrId == lrId
            ? l.copyWith(status: 'Delivered', deliveryStatus: 'delivered')
            : l)
        .toList();
    state = AsyncValue.data(updated);

    final details = ref.read(localTripSheetDetailsProvider);
    if (details != null) {
      final delivered =
          updated.where((l) => l.status.toLowerCase() == 'delivered').length;
      final pending = details.totalLrsCount > delivered
          ? details.totalLrsCount - delivered
          : 0;
      ref.read(localTripSheetDetailsProvider.notifier).state =
          details.copyWithCounts(
        deliveredLrsCount: delivered,
        pendingLrsCount: pending,
      );
    }
  }

  Future<void> markLRDelivered(String lrId, {required String tripSheetId}) async {
    // Call the backend first; only update local state once the server confirms.
    await ref.read(lrApiServiceProvider).updateDeliveryStatus(
          lrId: lrId,
          tripSheetId: tripSheetId,
        );

    _locallyDeliveredIds.add(lrId); // Save to local memory to survive fetch resets

    final currentState = state;
    if (currentState is AsyncData) {
      final List<LRModel> currentLrs = currentState.value ?? [];

      // We manually construct new models directly to guarantee 'status' updates for live APIs
      final strictlyUpdatedList = currentLrs.map((lr) {
        if (lr.lrId == lrId) {
           return LRModel(
            lrId: lr.lrId,
            lrNumber: lr.lrNumber,
            entryDate: lr.entryDate,
            consignorId: lr.consignorId,
            consignorName: lr.consignorName,
            consigneeId: lr.consigneeId,
            consigneeName: lr.consigneeName,
            fromBranchId: lr.fromBranchId,
            fromBranch: lr.fromBranch,
            toBranchId: lr.toBranchId,
            toBranch: lr.toBranch,
            quantity: lr.quantity,
            unitName: lr.unitName,
            amount: lr.amount,
            status: 'Delivered', // Explicitly update main live status
            billType: lr.billType,
          );
        }
        return lr;
      }).toList();

      state = AsyncValue.data(strictlyUpdatedList);
    }
  }
}

final lrListProvider = AsyncNotifierProvider<LRListNotifier, List<LRModel>>(() {
  return LRListNotifier();
});