import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/utils/gps_utils.dart';

class LrDetailScreen extends ConsumerStatefulWidget {
  final String lrId;

  const LrDetailScreen({super.key, required this.lrId});

  @override
  ConsumerState<LrDetailScreen> createState() => _LrDetailScreenState();
}

class _LrDetailScreenState extends ConsumerState<LrDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final lr = ref.watch(selectedLrProvider);
    final currentLoc = ref.watch(driverCurrentLocationProvider);
    final trip = ref.watch(selectedTripProvider);

    if (lr == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('LR Details')),
        body: const Center(child: Text('LR Details not found.')),
      );
    }

    final distance = currentLoc == null ? double.infinity : calculateHaversineDistance(
      currentLoc.latitude,
      currentLoc.longitude,
      lr.receiverLat,
      lr.receiverLng,
    );

    final isWithinRange = distance <= 2000.0;
    final isDelivered = lr.deliveryStatus == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: Text(lr.lrNumber),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (trip != null) {
              context.go('/driver/trips/${trip.tripId}/destinations/${lr.destination}');
            } else {
              context.go('/driver');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isDelivered
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.withOpacity(0.12)
                      : Colors.green.shade50)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.orange.shade50),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDelivered ? Colors.green : Colors.orange,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isDelivered ? Icons.check_circle : Icons.pending,
                      color: isDelivered ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered ? 'DELIVERED' : 'PENDING DELIVERY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDelivered ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                        ),
                        if (isDelivered && lr.deliveredAt != null)
                          Text(
                            'Delivered at: ${lr.deliveredAt!.hour.toString().padLeft(2, '0')}:${lr.deliveredAt!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LR Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _buildRowDetail(Icons.business, 'Sender', lr.consignorName),
                    _buildRowDetail(Icons.person, 'Consignee (Receiver)', lr.consigneeName),
                    _buildRowDetail(Icons.phone, 'Contact Phone', lr.consigneePhone),
                    _buildRowDetail(Icons.location_on, 'Delivery Address', lr.address),
                    _buildRowDetail(Icons.currency_rupee, 'To Pay Amount', '₹${lr.toPay.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isWithinRange ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radar,
                          color: isWithinRange ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GPS Verification Bounds',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      'Target Destination: Lat ${lr.receiverLat.toStringAsFixed(5)}, Lng ${lr.receiverLng.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      'Driver Current Location: Lat ${currentLoc?.latitude.toStringAsFixed(5) ?? 'N/A'}, Lng ${currentLoc?.longitude.toStringAsFixed(5) ?? 'N/A'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distance to Unload stop: ${distance.toStringAsFixed(1)} meters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isWithinRange ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!isWithinRange && !isDelivered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '⚠️ You must be within 2km of the delivery coordinate to mark as delivered.',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 12),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isDelivered)
              ElevatedButton.icon(
                onPressed: isWithinRange
                    ? () {
                        ref.read(firestoreServiceProvider).deliverLR(
                              lr.lrId,
                              currentLoc!.latitude,
                              currentLoc.longitude,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('LR Delivery Proof Synced!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    : () {
                        _showGpsBlockWarning(context, distance);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWithinRange ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.verified),
                label: const Text('Mark as Delivered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    ),
  );
}

  void _showGpsBlockWarning(BuildContext context, double distance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext BC) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gps_off_sharp, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Delivery Blocked!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You are currently ${(distance / 1000).toStringAsFixed(2)} km away from the client. Security protocols require you to be within 2 km of the delivery destination to submit proof.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(BC),
                  child: const Text('Return and Verify location'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRowDetail(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
