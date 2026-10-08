import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:infinity_roadlines/providers/trip_sheet_provider.dart';
import '../../models/lr_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/local_trip_list_provider.dart';
import '../../providers/lr_provider.dart';
import '../../services/local_trip_sheet_api_service.dart';
import 'local_delivery_dialog.dart';
import 'local_payment_dialog.dart';
import 'lr_map_tracker_dialog.dart';

class LrListScreen extends ConsumerStatefulWidget {
  final String tripId;

  const LrListScreen({super.key, required this.tripId});

  @override
  ConsumerState<LrListScreen> createState() => _LrListScreenState();
}

class _LrListScreenState extends ConsumerState<LrListScreen> {
  // tripsheet_type == "local" (read from the saved login session).
  bool _isLocal = false;
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    TripsheetType.isLocal().then((value) {
      if (mounted && value != _isLocal) setState(() => _isLocal = value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lrListProvider.notifier).fetchLRs(tripSheetId: widget.tripId);
    });
  }

  @override
  void dispose() {
    // Leaving the LR screen (back button, system back, after a delivery...)
    // returns to the Tripsheet page, which stays mounted underneath. Drop the
    // Local lists so they are fetched again from the API.
    if (_isLocal) {
      final container = _container;
      Future.microtask(() => container.invalidate(localTripListProvider));
    }
    super.dispose();
  }

  /// Local Topay payment: dialog -> check_lr_payment_status.php. The LR is only
  /// marked Paid after the backend confirms `is_paid == true`.
  Future<void> _showLocalPaymentDialog(LRModel lr) async {
    final messenger = ScaffoldMessenger.of(context);
    final lrNotifier = ref.read(lrListProvider.notifier);

    final result = await showLocalPaymentDialog(context: context, lr: lr);
    if (result == null) return;

    lrNotifier.applyLocalPayment(lr.lrId, result);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.message.isNotEmpty ? result.message : 'Payment recorded successfully.',
        ),
      ),
    );
  }

  /// Local Tripsheet delivery: popup -> update_local_lr_delivery.php ->
  /// (only if all_lrs_delivered == true) update_local_trip_sheet_status.php.
  void _showLocalDeliveryDialog(LRModel lr) {
    final messenger = ScaffoldMessenger.of(context);
    final lrNotifier = ref.read(lrListProvider.notifier);

    showLocalDeliveryDialog(
      context: context,
      localTripNumber: widget.tripId,
      lr: lr,
      onSubmit: (receivedPerson) async {
        try {
          final outcome = await lrNotifier.deliverLocalLR(
            lr: lr,
            receivedPerson: receivedPerson,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(outcome.result.message)),
          );

          if (outcome.tripStatusError != null) {
            // LR delivery already succeeded: keep it, only offer a retry of
            // the tripsheet status call.
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'LR delivered, but the tripsheet status could not be updated: ${outcome.tripStatusError}',
                ),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () async {
                    final error = await lrNotifier.retryLocalTripStatus();
                    if (error == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Tripsheet marked as Delivered')),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),
            );
          }
          // Tripsheet lists (Dispatched/Completed) reload when the home
          // screen is shown again.
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showDeliveryConfirmationDialog(String lrId) {
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Delivery Confirmation'),
              content: const Text('Are you sure you have delivered this LR?'),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(lrListProvider.notifier)
                                .markLRDelivered(
                                  lrId,
                                  tripSheetId: widget.tripId,
                                );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('LR Marked as Delivered'),
                              ),
                            );
                            ref.read(tripSheetsProvider.notifier).fetchTripSheets();
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lrsAsync = ref.watch(lrListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LR List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(lrListProvider.notifier)
              .fetchLRs(tripSheetId: widget.tripId),
          child: lrsAsync.when(
            data: (lrs) {
              if (lrs.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        'No LRs assigned or found.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lrs.length,
                itemBuilder: (context, index) {
                  final lr = lrs[index];
                  final isPending = lr.status.toLowerCase() != 'delivered';
                  // && lr.status.toLowerCase() != 'pending';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'LR: ${lr.lrNumber}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLocal && lr.isTopay && lr.isPaid) ...[
                                    _buildPaidChip(),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildStatusBadge(lr.status),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            'Date: ${lr.entryDate}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consignor: ${lr.consignorName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consignee: ${lr.consigneeName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          if (!_isLocal || lr.fromBranch.isNotEmpty || lr.toBranch.isNotEmpty)
                            Text(
                              'Route: ${lr.fromBranch}  ➔  ${lr.toBranch}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          // Local Tripsheet extras (empty for General LRs).
                          if (_isLocal && lr.parentTripNumber.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Parent Tripsheet: ${lr.parentTripNumber}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.consigneePhone.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Consignee Mobile: ${lr.consigneePhone}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.consignorPhone.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Consignor Mobile: ${lr.consignorPhone}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Address: ${lr.address}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.billType.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Bill Type: ${lr.billType}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.paymentMode.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Payment Mode: ${lr.paymentMode}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.isTopay) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Payment Status: ${lr.isPaid ? 'Paid' : lr.paymentStatus}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: lr.isPaid ? FontWeight.bold : FontWeight.normal,
                                color: lr.isPaid ? Colors.green : null,
                              ),
                            ),
                          ],
                          if (_isLocal && lr.isPaid && lr.razorpayPaymentId.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Payment ID: ${lr.razorpayPaymentId}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.deliveryPin.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Delivery PIN: ${lr.deliveryPin}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (_isLocal && lr.collectableAmount > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                                'Collectable Amount: ₹${lr.collectableAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                          if (lr.weight.toString() != "")
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lr.weight.toString() != "")
                                      Text(
                                        'Weight: ${lr.weight}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    if (lr.quantity.toString() != "")
                                      const SizedBox(height: 6),
                                    if (lr.quantity.toString() != "")
                                      Text(
                                        'Quantity: ${lr.quantity} ${lr.unitName}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Amount: ₹${lr.amount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),

                          // Local Topay: Pay button. Hidden once the backend has
                          // confirmed the payment (no repeat payments).
                          if (_isLocal && lr.isTopay && !lr.isPaid) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showLocalPaymentDialog(lr),
                                icon: const Icon(Icons.payments),
                                label: const Text('Pay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],

                          if (isPending) ...[
                            const SizedBox(height: 16),
                            (() {
                              final currentLocation = ref.watch(
                                driverCurrentLocationProvider,
                              );
                              bool hasValidDestination =
                                  lr.receiverLat != 0.0 &&
                                  lr.receiverLng != 0.0;
                              double distanceInMeters = 0.0;
                              bool isWithinRange = false;

                              if (hasValidDestination &&
                                  currentLocation != null) {
                                distanceInMeters = Geolocator.distanceBetween(
                                  currentLocation.latitude,
                                  currentLocation.longitude,
                                  lr.receiverLat,
                                  lr.receiverLng,
                                );
                                isWithinRange = distanceInMeters <= 2000.0;
                              }

                              if (!hasValidDestination) {
                                return Opacity(
                                  opacity: 0.6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: null,
                                        icon: const Icon(Icons.location_off),
                                        label: const Text('Delivered'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Destination location unavailable.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Column(
                                  children: [
                                    if (!isWithinRange) ...[
                                      Opacity(
                                        opacity: 0.6,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.block),
                                              label: const Text('Delivered'),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'You must reach the destination before marking this LR as Delivered.',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              'Distance to destination: ${distanceInMeters >= 1000 ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km' : '${distanceInMeters.toStringAsFixed(0)} meters'}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _isLocal
                                              ? _showLocalDeliveryDialog(lr)
                                              : _showDeliveryConfirmationDialog(
                                                  lr.lrId,
                                                ),
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Delivered'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    /*const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: currentLocation == null ? null : () => showLrMapTrackerSheet(
                                          context: context, 
                                          driverLocation: currentLocation, 
                                          lr: lr
                                        ),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('View Route'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),*/
                                  ],
                                );
                              }
                            })(),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(lrListProvider.notifier)
                          .fetchLRs(tripSheetId: widget.tripId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Green "PAID" chip shown next to the delivery badge once payment is confirmed.
  Widget _buildPaidChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: const Text(
        'PAID',
        style: TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isDelivered = status.toLowerCase() == 'delivered';
    final color = isDelivered ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}