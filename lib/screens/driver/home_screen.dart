import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trip_sheet_provider.dart';
import '../../providers/trip_card_provider.dart';
import '../../providers/lr_provider.dart';
import '../../models/trip_model.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripSheetsProvider.notifier).fetchTripSheets();
      ref.read(tripCardsProvider.notifier).fetchTripCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(driverLocationNotifierProvider);

    final user = ref.watch(authStateProvider).value;
    final tripsAsync = ref.watch(driverTripsProvider);
    final tripCardsAsync = ref.watch(driverTripCardsProvider);
    final currentLocation = ref.watch(driverCurrentLocationProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isGpsEnabled = ref.watch(isGpsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user != null ? 'Welcome, ${user.name}' : 'Today\'s Activity',
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .state = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/driver/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: isGpsEnabled
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isGpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                    color: isGpsEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isGpsEnabled) ...[
                          Text(
                            'GPS Disabled - Please Enable Location Services',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ] else if (currentLocation == null) ...[
                          Text(
                            'Acquiring Satellite GPS Signal...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'GPS Active: Lat ${currentLocation.latitude.toStringAsFixed(4)}, Lng ${currentLocation.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Battery: ${currentLocation.battery.toStringAsFixed(0)}% • Syncing Real-Time',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Active Trip Sheet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tripsAsync.when(
                      data: (trips) {
                        if (trips.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No Trip Sheet Assigned',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            final trip = trips[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          trip.tripNo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        _buildStatusBadge(
                                          trip.acknowledgementStatus,
                                          context,
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      'Trip Date: ${trip.date.day.toString().padLeft(2, '0')}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.year}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vehicle Number: ${trip.vehicleNumber}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Driver Name: ${trip.driverName}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Destination: ${trip.toStops.join(" ➔ ")}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LR Count: ${trip.totalLR}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),

                                    if (trip.remarks.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Remarks: ${trip.remarks}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _TripActionSection(trip: trip),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
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
                                  .read(tripSheetsProvider.notifier)
                                  .fetchTripSheets(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trip Cards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tripCardsAsync.when(
                      data: (cards) {
                        if (cards.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No Trip Cards Assigned',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trip Card: ${card.tripCardNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      'Date: ${card.entryDate.day.toString().padLeft(2, '0')}-${card.entryDate.month.toString().padLeft(2, '0')}-${card.entryDate.year}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vehicle Check: ${card.vehicleNumber}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Driver Name: ${card.driverName}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Route: ${card.fromBranch} ➔ ${card.toBranch}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${card.quantity} ${card.unitName}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Driver Salary: ₹${card.driverSalary}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
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
                                  .read(tripCardsProvider.notifier)
                                  .fetchTripCards(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _acknowledgementColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _acknowledgementColor(status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _acknowledgementColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color _acknowledgementColor(String acknowledgementStatus) {
  switch (acknowledgementStatus.toLowerCase()) {
    case 'accepted':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.orange;
  }
}

/// Renders the correct action for a trip sheet card based on its
/// trip_status and acknowledgement_status:
/// - trip_status == Completed          -> "Completed" button only
/// - acknowledgement_status == Pending -> "Accept" / "Reject" buttons
/// - acknowledgement_status == Rejected -> no button (status text only)
/// - acknowledgement_status == Accepted -> normal "Start Trip" / "View Trip Sheet" flow
class _TripActionSection extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TripActionSection({required this.trip});

  @override
  ConsumerState<_TripActionSection> createState() => _TripActionSectionState();
}

class _TripActionSectionState extends ConsumerState<_TripActionSection> {
  bool _isSubmitting = false;

  Future<void> _handleAcknowledge(String status) async {
    setState(() => _isSubmitting = true);
    try {
      final confirmed = await ref
          .read(tripSheetsProvider.notifier)
          .acknowledgeTrip(tripSheetId: widget.trip.tripId, status: status);
      if (!confirmed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update trip status. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final tripStatus = trip.status.toLowerCase();
    final ackStatus = trip.acknowledgementStatus.toLowerCase();

    // // Trip is fully completed -> show "Completed" only, regardless of acknowledgement.
    // if (tripStatus == 'completed') {
    //   return SizedBox(
    //     width: double.infinity,
    //     child: ElevatedButton(
    //       onPressed: null,
    //       style: ElevatedButton.styleFrom(
    //         backgroundColor: Colors.green,
    //         foregroundColor: Colors.white,
    //         disabledBackgroundColor: Colors.green,
    //         disabledForegroundColor: Colors.white,
    //       ),
    //       child: const Text('Completed'),
    //     ),
    //   );
    // }

    // Awaiting driver's decision -> show Accept / Reject.
    if (ackStatus == 'pending') {
      if (_isSubmitting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleAcknowledge('Accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleAcknowledge('Rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }

    // Driver rejected the trip -> no action button, the status text above is enough.
    if (ackStatus == 'rejected') {
      // return const SizedBox.shrink();
      return SizedBox(
        width: double.infinity,
        child:  ElevatedButton(
              onPressed: () {
                ref.read(selectedTripIdProvider.notifier).state = trip.tripId;
                
                context.go('/driver/trips/${trip.tripId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'View Trip Sheet',
              ),
            )
      );
    }

    // Accepted -> normal Start Trip / View Trip Sheet flow.
    return SizedBox(
      width: double.infinity,
      child: Consumer(
        builder: (context, ref, child) {
          final selectedTripId = ref.watch(selectedTripIdProvider);
          final lrsAsync = ref.watch(lrListProvider);
          bool allDelivered = false;
          if (selectedTripId == trip.tripId &&
              lrsAsync.value != null &&
              lrsAsync.value!.isNotEmpty) {
            allDelivered = lrsAsync.value!.every(
              (lr) => lr.status.toLowerCase() == 'delivered',
            );
          }
          final displayStatus = allDelivered ? 'completed' : tripStatus;

          return ElevatedButton(
            onPressed: () {
              ref.read(selectedTripIdProvider.notifier).state = trip.tripId;
              if (tripStatus == 'pending') {
                ref
                    .read(firestoreServiceProvider)
                    .updateTripStatus(trip.tripId, 'started');
              }
              context.go('/driver/trips/${trip.tripId}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tripStatus == 'completed'
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              tripStatus == 'completed'
                  ? 'Completed'
                  : (tripStatus == 'pending'
                        ? 'Start Trip'
                        : 'View Trip Sheet'),
            ),
          );
        },
      ),
    );
  }
}
