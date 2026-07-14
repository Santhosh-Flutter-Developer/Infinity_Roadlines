import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lr_model.dart';
import '../services/lr_api_service.dart';

final lrApiServiceProvider = Provider<LRApiService>((ref) {
  return LRApiService();
});

class LRListNotifier extends AsyncNotifier<List<LRModel>> {
  final Set<String> _locallyDeliveredIds = {}; // Local memory cache for optimistic updates

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

  Future<void> markLRDelivered(String lrId) async {
    _locallyDeliveredIds.add(lrId); // Save to local memory to survive fetch resets

    final currentState = state;
    if (currentState is AsyncData) {
      final List<LRModel> currentLrs = currentState.value ?? [];
      final updatedList = currentLrs.map((lr) {
        if (lr.lrId == lrId) {
          return lr.copyWith(deliveryStatus: 'Delivered');
          // Note: Since 'status' wasn't natively mapped in copyWith for the live api field, we explicitly override status
        }
        return lr;
      }).toList();
      
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
