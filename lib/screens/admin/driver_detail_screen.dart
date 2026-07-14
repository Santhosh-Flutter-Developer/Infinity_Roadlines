import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';

class AdminDriverDetailScreen extends ConsumerWidget {
  final String driverUid;

  const AdminDriverDetailScreen({super.key, required this.driverUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(adminDriversProvider);
    final tripsAsync = ref.watch(firestoreServiceProvider).watchTripsForDriver(driverUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: driversAsync.when(
        data: (drivers) {
          final driver = drivers.firstWhere((d) => d.uid == driverUid, orElse: () => throw Exception('Driver not found'));
          final statusColor = driver.status == 'driving'
              ? Colors.green
              : (driver.status == 'online' ? Colors.blue : Colors.grey);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.person, size: 36, color: statusColor),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          driver.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${driver.username} • Phone: ${driver.phone}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            driver.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Telemetry & GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Divider(),
                        _buildInfoRow(context, Icons.battery_charging_full, 'Device Battery', '${driver.battery.toStringAsFixed(0)}%'),
                        _buildInfoRow(context, Icons.speed, 'Simulated Speed', driver.status == 'driving' ? '54 km/h' : '0 km/h'),
                        if (driver.lastLocation != null) ...[
                          _buildInfoRow(context, Icons.location_on, 'Latitude', '${driver.lastLocation!['lat']}'),
                          _buildInfoRow(context, Icons.location_on, 'Longitude', '${driver.lastLocation!['lng']}'),
                          _buildInfoRow(context, Icons.update, 'Last Updated', driver.lastLocation!['updatedAt']),
                        ] else
                          const Text('No GPS updates received yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Assigned Trips Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: tripsAsync,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final trips = snapshot.data ?? [];
                    if (trips.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No trips assigned for this driver.', style: TextStyle(color: Colors.grey)),
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
                          child: ListTile(
                            title: Text(trip.tripNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Route: ${trip.from} ➔ ${trip.toStops.join(" ➔ ")}'),
                            trailing: Text(
                              trip.status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: trip.status == 'completed'
                                    ? Colors.green
                                    : (trip.status == 'started' ? Colors.orange : Colors.blue),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final labelColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;
    final iconColor = theme.colorScheme.onSurface.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: labelColor)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
