import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/trip_provider.dart';
import '../../models/user_model.dart';

class AdminLiveMapScreen extends ConsumerStatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  ConsumerState<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends ConsumerState<AdminLiveMapScreen> {
  bool _useGoogleMaps = false;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dispatch Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          Row(
            children: [
              const Text('Google Maps', style: TextStyle(fontSize: 12)),
              Switch(
                value: _useGoogleMaps,
                onChanged: (val) {
                  setState(() {
                    _useGoogleMaps = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: driversAsync.when(
        data: (drivers) {
          if (_useGoogleMaps) {
            return _buildGoogleMaps(drivers);
          } else {
            return _buildCustomSimulatedMap(drivers);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildGoogleMaps(List<UserModel> drivers) {
    final markers = drivers
        .where((d) => d.lastLocation != null)
        .map((d) {
          final lat = d.lastLocation!['lat'] as double;
          final lng = d.lastLocation!['lng'] as double;
          return Marker(
            markerId: MarkerId(d.uid),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: d.name,
              snippet: '${d.vehicleNumber} • ${d.status.toUpperCase()}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              d.status == 'driving' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
            ),
          );
        })
        .toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(10.5, 77.8),
        zoom: 7.5,
      ),
      markers: markers,
    );
  }

  Widget _buildCustomSimulatedMap(List<UserModel> drivers) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MapGridPainter(drivers: drivers),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Live Simulated Transit Grid',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              final hasLoc = d.lastLocation != null;
              final lat = hasLoc ? (d.lastLocation!['lat'] as double) : 0.0;
              final lng = hasLoc ? (d.lastLocation!['lng'] as double) : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: hasLoc
                      ? Text('Loc: (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) • Battery: ${d.battery.toStringAsFixed(0)}%')
                      : const Text('No location synced'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.status == 'driving' ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d.status.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: d.status == 'driving' ? Colors.green : Colors.blue),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MapGridPainter extends CustomPainter {
  final List<UserModel> drivers;

  MapGridPainter({required this.drivers});

  Offset _getOffsetForLatLng(double lat, double lng, Size size) {
    const minLat = 9.20;
    const maxLat = 11.50;
    const minLng = 76.70;
    const maxLng = 78.50;

    final y = size.height * (1.0 - (lat - minLat) / (maxLat - minLat));
    final x = size.width * ((lng - minLng) / (maxLng - minLng));

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.blueGrey.shade800.withOpacity(0.5)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final cities = {
      'Sivakasi': const Offset(9.4526, 77.8016),
      'Madurai': const Offset(9.9252, 78.1198),
      'Karur': const Offset(10.9602, 78.0770),
      'Erode': const Offset(11.3410, 77.7172),
      'Tirupur': const Offset(11.1085, 77.3411),
      'Coimbatore': const Offset(11.0168, 76.9558),
    };

    final routePaint = Paint()
      ..color = Colors.teal.shade700
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final pSivakasi = _getOffsetForLatLng(9.4526, 77.8016, size);
    final pMadurai = _getOffsetForLatLng(9.9252, 78.1198, size);
    final pKarur = _getOffsetForLatLng(10.9602, 78.0770, size);
    final pErode = _getOffsetForLatLng(11.3410, 77.7172, size);
    final pTirupur = _getOffsetForLatLng(11.1085, 77.3411, size);
    final pCoimbatore = _getOffsetForLatLng(11.0168, 76.9558, size);

    path.moveTo(pSivakasi.dx, pSivakasi.dy);
    path.lineTo(pMadurai.dx, pMadurai.dy);
    path.lineTo(pKarur.dx, pKarur.dy);
    path.lineTo(pErode.dx, pErode.dy);
    path.lineTo(pTirupur.dx, pTirupur.dy);
    path.lineTo(pCoimbatore.dx, pCoimbatore.dy);

    canvas.drawPath(path, routePaint);

    final nodePaint = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;

    final namePainterStyle = const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold);

    cities.forEach((name, latLng) {
      final pos = _getOffsetForLatLng(latLng.dx, latLng.dy, size);
      
      canvas.drawCircle(pos, 6, nodePaint);
      canvas.drawCircle(pos, 10, Paint()..color = Colors.amber.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

      final textSpan = TextSpan(text: name, style: namePainterStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(pos.dx + 8, pos.dy - 6));
    });

    for (final driver in drivers) {
      if (driver.lastLocation == null) continue;
      final lat = driver.lastLocation!['lat'] as double;
      final lng = driver.lastLocation!['lng'] as double;
      final pos = _getOffsetForLatLng(lat, lng, size);

      final markerColor = driver.status == 'driving' ? Colors.greenAccent : Colors.lightBlueAccent;

      canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = markerColor.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        pos,
        8,
        Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill,
      );

      final textSpan = TextSpan(
        text: '${driver.name.split(" ")[0]} (${driver.vehicleNumber ?? ""})',
        style: TextStyle(color: markerColor, fontSize: 9, fontWeight: FontWeight.bold, backgroundColor: Colors.black87),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy - 22));
    }
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) => true;
}
