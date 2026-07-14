import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/utils/gps_utils.dart';
import '../../models/lr_model.dart';

class LrDestinationListScreen extends ConsumerWidget {
  final String tripId;

  const LrDestinationListScreen({super.key, required this.tripId});

  void _showDeliveryConfirmation(
    BuildContext context,
    WidgetRef ref,
    String stop,
    List<LRModel> stopLrs,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestinationDeliveryDialog(
        stop: stop,
        stopLrs: stopLrs,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch location simulation notifier to ensure location updates are active
    ref.watch(driverLocationNotifierProvider);

    final tripAsync = ref.watch(driverTripsProvider);
    final lrsAsync = ref.watch(selectedTripLRsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Stops & Destinations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: SafeArea(
        child: tripAsync.when(
          data: (trips) {
            final trip = trips.firstWhere((t) => t.tripId == tripId, orElse: () => throw Exception('Trip not found'));
            return lrsAsync.when(
              data: (lrs) {
                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          width: 1.5,
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
                                  trip.tripNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '${lrs.where((lr) => lr.deliveryStatus == 'delivered').length}/${lrs.length} Delivered',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('From: ${trip.from}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Location Stop',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trip.toStops.length,
                        itemBuilder: (context, index) {
                          final stop = trip.toStops[index];
                          final stopLrs = lrs.where((lr) => lr.destination.toLowerCase() == stop.toLowerCase()).toList();
                          final total = stopLrs.length;
                          final delivered = stopLrs.where((lr) => lr.deliveryStatus == 'delivered').length;
                          final isCompleted = total > 0 && delivered == total;

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isCompleted
                                    ? Colors.green.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                                width: isCompleted ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                stop,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                '$total LRs (parcels) • $delivered / $total delivered',
                                style: TextStyle(
                                  color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: total > 0
                                  ? Switch.adaptive(
                                      value: isCompleted,
                                      activeThumbColor: Colors.green,
                                      activeTrackColor: Colors.green.withOpacity(0.5),
                                      onChanged: isCompleted
                                          ? null
                                          : (bool value) {
                                              if (value) {
                                                _showDeliveryConfirmation(context, ref, stop, stopLrs);
                                              }
                                            },
                                    )
                                  : const Icon(Icons.remove_circle_outline, color: Colors.grey),
                              onTap: total > 0 && !isCompleted
                                  ? () => _showDeliveryConfirmation(context, ref, stop, stopLrs)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    if (lrs.isNotEmpty && lrs.every((lr) => lr.deliveryStatus == 'delivered') && trip.status != 'completed')
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).updateTripStatus(tripId, 'completed');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Trip marked as COMPLETED!')),
                              );
                              context.go('/driver');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Complete Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading LRs: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading Trip: $err')),
        ),
      ),
    );
  }
}

class DestinationDeliveryDialog extends ConsumerWidget {
  final String stop;
  final List<LRModel> stopLrs;

  const DestinationDeliveryDialog({
    super.key,
    required this.stop,
    required this.stopLrs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLoc = ref.watch(driverCurrentLocationProvider);

    // Reference coordinates from the first LR of this destination
    final refLat = stopLrs.isNotEmpty ? stopLrs.first.receiverLat : 0.0;
    final refLng = stopLrs.isNotEmpty ? stopLrs.first.receiverLng : 0.0;

    final distance = currentLoc == null ? double.infinity : calculateHaversineDistance(
      currentLoc.latitude,
      currentLoc.longitude,
      refLat,
      refLng,
    );

    final isWithinRange = distance <= 2000.0;

    return AlertDialog(
      title: Text('Confirm Delivery - $stop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Are you sure you want to mark all parcels for this stop as delivered?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'This will mark all ${stopLrs.length} parcel(s) as delivered.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.radar,
                  color: isWithinRange ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'GPS Verification',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (kDebugMode) ...[
              Text(
                'Target stop: Lat ${refLat.toStringAsFixed(5)}, Lng ${refLng.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Driver current loc: Lat ${currentLoc?.latitude.toStringAsFixed(5) ?? 'N/A'}, Lng ${currentLoc?.longitude.toStringAsFixed(5) ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Distance to Stop: ${distance.toStringAsFixed(1)} meters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isWithinRange ? Colors.green : Colors.red,
              ),
            ),
            if (!isWithinRange)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '⚠️ Delivery Blocked! You must be within 2km of the destination. You are currently ${(distance / 1000).toStringAsFixed(2)} km away.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                ),
              ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isWithinRange
              ? () async {
                  final firestore = ref.read(firestoreServiceProvider);
                  for (final lr in stopLrs) {
                    if (lr.deliveryStatus != 'delivered') {
                      await firestore.deliverLR(
                        lr.lrId,
                        currentLoc!.latitude,
                        currentLoc.longitude,
                      );
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('All $stop parcels marked as DELIVERED!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isWithinRange ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
