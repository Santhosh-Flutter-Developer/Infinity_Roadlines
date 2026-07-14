// Dashboard screen for Driver (V2 layout)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch data
    ref.watch(driverLocationNotifierProvider);
    final user = ref.watch(authStateProvider).value;
    final tripsAsync = ref.watch(driverTripsProvider);
    final currentLocation = ref.watch(driverCurrentLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? 'Welcome, ${user.name}' : "Today's Trips"),
        actions: [
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
      body: Column(
        children: [
          // GPS status banner
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentLocation != null
                        ? 'GPS Active: Lat ${currentLocation.latitude.toStringAsFixed(4)}, Lng ${currentLocation.longitude.toStringAsFixed(4)} (Battery: ${currentLocation.battery.toStringAsFixed(0)}%)'
                        : 'GPS Acquiring...',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Quick actions grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _quickAction(context, Icons.add, 'New Trip', () => context.go('/driver/trips/new')),
                _quickAction(context, Icons.history, 'History', () => context.go('/driver/history')),
                _quickAction(context, Icons.settings, 'Settings', () => context.go('/driver/profile')),
              ],
            ),
          ),
          // Trips list
          Expanded(
            child: tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return const Center(child: Text('No trips assigned for today.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(trip.tripNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Vehicle: ${trip.vehicleNumber} • ${trip.from} → ${trip.toStops.join(' → ')}'),
                        trailing: _statusBadge(trip.status, context),
                        onTap: () => context.go('/driver/trips/${trip.tripId}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'started':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
