import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/lr_model.dart';
import '../../services/gps_service.dart';

void showLrMapTrackerSheet({
  required BuildContext context,
  required PositionData driverLocation,
  required LRModel lr,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _MapTrackerWidget(
            driverLocation: driverLocation,
            lr: lr,
          ),
        ),
      );
    },
  );
}

class _MapTrackerWidget extends StatefulWidget {
  final PositionData driverLocation;
  final LRModel lr;

  const _MapTrackerWidget({
    required this.driverLocation,
    required this.lr,
  });

  @override
  State<_MapTrackerWidget> createState() => _MapTrackerWidgetState();
}

class _MapTrackerWidgetState extends State<_MapTrackerWidget> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    debugPrint('[LR TRACKER MAP] Launching map tracking UI overlay.');
    final driverLatLng = LatLng(widget.driverLocation.latitude, widget.driverLocation.longitude);
    final destinationLatLng = LatLng(widget.lr.receiverLat, widget.lr.receiverLng);

    // Explicit calculation constraints natively overlaying lines
    final distanceInMeters = Geolocator.distanceBetween(
      driverLatLng.latitude, driverLatLng.longitude,
      destinationLatLng.latitude, destinationLatLng.longitude,
    );
    debugPrint('[LR TRACKER MAP] Euclidean distance strictly parsed at ${distanceInMeters.toStringAsFixed(2)} meters.');

    final markers = {
      Marker(
        markerId: const MarkerId('driver_marker'),
        position: driverLatLng,
        infoWindow: const InfoWindow(title: 'Current Location', snippet: 'Your truck is here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue for driver
      ),
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: destinationLatLng,
        infoWindow: InfoWindow(title: 'Destination', snippet: '${widget.lr.toBranch} Branch'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red for destination
      )
    };

    final polyline = Polyline(
      polylineId: const PolylineId('route_line'),
      points: [driverLatLng, destinationLatLng],
      color: distanceInMeters <= 2000 ? Colors.green : Colors.redAccent,
      width: 4,
      patterns: [PatternItem.dash(15.0), PatternItem.gap(10.0)],
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Route: ${widget.lr.fromBranch}  ➔  ${widget.lr.toBranch}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: driverLatLng,
              zoom: 13,
            ),
            markers: markers,
            polylines: {polyline},
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      driverLatLng.latitude < destinationLatLng.latitude ? driverLatLng.latitude : destinationLatLng.latitude,
                      driverLatLng.longitude < destinationLatLng.longitude ? driverLatLng.longitude : destinationLatLng.longitude,
                    ),
                    northeast: LatLng(
                      driverLatLng.latitude > destinationLatLng.latitude ? driverLatLng.latitude : destinationLatLng.latitude,
                      driverLatLng.longitude > destinationLatLng.longitude ? driverLatLng.longitude : destinationLatLng.longitude,
                    ),
                  ),
                  100.0, // generous padding
                ),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Direct Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    distanceInMeters >= 1000 
                      ? '${(distanceInMeters / 1000).toStringAsFixed(2)} km' 
                      : '${distanceInMeters.toStringAsFixed(0)} meters',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: distanceInMeters <= 2000 ? Colors.green : Colors.orange
                    ),
                  ),
                  if (distanceInMeters > 2000)
                    const Text('Move closer to unlock delivery.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    const Text('Target Reached. Delivery Unlocked.', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
