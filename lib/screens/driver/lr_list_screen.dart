import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/location_provider.dart';
import '../../providers/lr_provider.dart';
import 'lr_map_tracker_dialog.dart';

class LrListScreen extends ConsumerStatefulWidget {
  final String tripId;

  const LrListScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<LrListScreen> createState() => _LrListScreenState();
}

class _LrListScreenState extends ConsumerState<LrListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lrListProvider.notifier).fetchLRs(tripSheetId: widget.tripId);
    });
  }

  void _showDeliveryConfirmationDialog(String lrId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delivery Confirmation'),
          content: const Text('Are you sure you have delivered this LR?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(lrListProvider.notifier).markLRDelivered(lrId);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('LR Marked as Delivered')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
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
          onRefresh: () => ref.read(lrListProvider.notifier).fetchLRs(tripSheetId: widget.tripId),
          child: lrsAsync.when(
            data: (lrs) {
              if (lrs.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        'No LRs assigned or found.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                              Text(
                                'LR: ${lr.lrNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              _buildStatusBadge(lr.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('Date: ${lr.entryDate}', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('Consignor: ${lr.consignorName}', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('Consignee: ${lr.consigneeName}', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('Route: ${lr.fromBranch}  ➔  ${lr.toBranch}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantity: ${lr.quantity} ${lr.unitName}', style: const TextStyle(fontSize: 14)),
                              Text('Amount: ₹${lr.amount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            (() {
                              final currentLocation = ref.watch(driverCurrentLocationProvider);
                              bool hasValidDestination = lr.receiverLat != 0.0 && lr.receiverLng != 0.0;
                              double distanceInMeters = 0.0;
                              bool isWithinRange = false;

                              if (hasValidDestination && currentLocation != null) {
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
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: null,
                                        icon: const Icon(Icons.location_off),
                                        label: const Text('Delivered'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Destination location unavailable.',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
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
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.block),
                                              label: const Text('Delivered'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'You must reach the destination before marking this LR as Delivered.',
                                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              'Distance to destination: ${distanceInMeters >= 1000 ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km' : '${distanceInMeters.toStringAsFixed(0)} meters'}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    ] else ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showDeliveryConfirmationDialog(lr.lrId),
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Delivered'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      )
                                    ],
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: currentLocation == null ? null : () => showLrMapTrackerSheet(
                                          context: context, 
                                          driverLocation: currentLocation!, 
                                          lr: lr
                                        ),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('View Route'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),
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
                    Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(lrListProvider.notifier).fetchLRs(tripSheetId: widget.tripId),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
