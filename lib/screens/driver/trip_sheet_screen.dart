import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/trip_model.dart';
import '../../models/lr_model.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/gps_service.dart';

class TripSheetScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripSheetScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripSheetScreen> createState() => _TripSheetScreenState();
}

class _TripSheetScreenState extends ConsumerState<TripSheetScreen> {
  final TextEditingController _remarksController = TextEditingController();
  bool _isRemarksInitialized = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _generateAndPrintPDF(TripModel trip, List<LRModel> lrs) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(trip.companyInfo['name'] ?? 'Infinity Roadlines',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Trip Sheet No: ${trip.tripNo}'),
                      pw.Text('Date: ${trip.date.day.toString().padLeft(2, '0')}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.year}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Trip Info
              pw.Text('TRIP INFO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('From: ${trip.from}'),
                  pw.Text('To Stops: ${trip.toStops.join(', ')}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vehicle: ${trip.vehicleNumber} (${trip.vehicleName})'),
                  pw.Text('Driver: ${trip.driverName} (${trip.driverMobile})'),
                ],
              ),
              pw.Text('Status: ${trip.status}'),
              pw.SizedBox(height: 15),

              // Summary Totals
              pw.Text('SUMMARY TOTALS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total LRs: ${trip.totalLR}'),
                  pw.Text('Delivered: ${trip.deliveredLR}'),
                  pw.Text('Pending: ${trip.pendingLR}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cooly: ₹${trip.totals['cooly']}'),
                  pw.Text('Freight Amount: ₹${trip.totals['amount']}'),
                  pw.Text('To Pay: ₹${trip.totals['toPay']}'),
                ],
              ),
              pw.SizedBox(height: 15),

              // LR Table Header
              pw.Text('LORRY RECEIPTS (LRs)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FixedColumnWidth(25),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(3),
                  4: pw.FixedColumnWidth(30),
                  5: pw.FixedColumnWidth(40),
                  6: pw.FixedColumnWidth(45),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('LR No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Consignor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Consignee', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('To Pay', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  // Data Rows
                  ...lrs.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final lr = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(lr.lrNumber, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(lr.consignorName, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(lr.consigneeName, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${lr.qty}', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('₹${lr.toPay.toInt()}', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(lr.deliveryStatus == 'delivered' ? 'Delivered' : 'Pending', style: pw.TextStyle(fontSize: 8, color: lr.deliveryStatus == 'delivered' ? PdfColors.green800 : PdfColors.orange800))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 15),

              // Bottom Totals & Remarks
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Freight Charges: ₹${trip.totals['freight']}', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Cooly Charges: ₹${trip.totals['coolyCharges']}', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Total Amount: ₹${trip.totals['totalAmount']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Remarks: ${trip.remarks}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('For ${trip.companyInfo['name']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 20),
                    pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(driverTripsProvider);
    final position = ref.watch(driverCurrentLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Trip Sheet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading trip details: $err')),
          data: (trips) {
            final tripIndex = trips.indexWhere((t) => t.tripId == widget.tripId);
            if (tripIndex == -1) {
              return const Center(child: Text('Trip not found.'));
            }
            final trip = trips[tripIndex];
  
            ref.read(selectedTripIdProvider.notifier).state = widget.tripId;
      final lrsAsync = ref.watch(selectedTripLRsProvider);

          return lrsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading LRs: $err')),
            data: (lrs) {
              if (!_isRemarksInitialized) {
                _remarksController.text = trip.remarks;
                _isRemarksInitialized = true;
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Section 1: Header
                        _buildSectionHeader(trip),
                        const SizedBox(height: 16),

                        // Section 2: Trip Info
                        _buildTripInfoSection(trip, position),
                        const SizedBox(height: 16),

                        // Section 3: Summary Totals
                        _buildSummaryTotalsSection(trip),
                        const SizedBox(height: 16),

                        // Section 4: LR Table
                        _buildLRTableSection(trip, lrs),
                        const SizedBox(height: 16),

                        // Section 5: Bottom Totals & Signature
                        _buildBottomTotalsSection(trip),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Floating Action Buttons (Sticky Bottom layout)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, -2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                            onPressed: () => _generateAndPrintPDF(trip, lrs),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text('Share PDF'),
                            onPressed: () => _generateAndPrintPDF(trip, lrs), // Reuses layoutPdf window as fallback
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            onPressed: () => _generateAndPrintPDF(trip, lrs), // Reuses layoutPdf window as fallback
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

  // Section 1 UI: Header
  Widget _buildSectionHeader(TripModel trip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Colors.teal, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.companyInfo['name'] ?? 'Infinity Roadlines',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trip Sheet No: ${trip.tripNo}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${trip.date.day.toString().padLeft(2, '0')}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section 2 UI: Trip Info
  Widget _buildTripInfoSection(TripModel trip, PositionData? position) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TRIP INFO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.teal)),
            const Divider(),
            const SizedBox(height: 4),
            _buildInfoRow('From', trip.from),
            _buildInfoRow('To Stops', trip.toStops.join(', ')),
            _buildInfoRow('Vehicle No', trip.vehicleNumber),
            _buildInfoRow('Vehicle Name', trip.vehicleName),
            _buildInfoRow('Driver', trip.driverName),
            _buildInfoRow('Mobile', trip.driverMobile),
            _buildInfoRow('GPS Status', trip.gpsStatus),
            _buildInfoRow('Location', position != null ? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}' : 'Acquiring...'),
          ],
        ),
      ),
    );
  }

  // Section 3 UI: Summary Totals
  Widget _buildSummaryTotalsSection(TripModel trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUMMARY TOTALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.teal)),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTotalMetric('Total LR', '${trip.totalLR}'),
                _buildTotalMetric('Delivered', '${trip.deliveredLR}'),
                _buildTotalMetric('Pending', '${trip.pendingLR}'),
                _buildTotalMetric('Cancelled', '${trip.cancelledLR}'),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Branches', trip.branches.join(', ')),
            _buildInfoRow('Amount', '₹${trip.totals['amount']}'),
            _buildInfoRow('Weight', '${trip.totals['weight']} tons'),
            _buildInfoRow('Cooly', '₹${trip.totals['cooly']}'),
            _buildInfoRow('To Pay', '₹${trip.totals['toPay']}'),
            _buildInfoRow('Paid', '₹${trip.totals['paid']}'),
            _buildInfoRow('Account', '₹${trip.totals['account']}'),
          ],
        ),
      ),
    );
  }

  // Section 4 UI: LR Table
  Widget _buildLRTableSection(TripModel trip, List<LRModel> lrs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'LORRY RECEIPTS (LRs) — Tap row to view details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
              ),
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 52,
                columnSpacing: 14,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('LR No')),
                  DataColumn(label: Text('Consignor')),
                  DataColumn(label: Text('Consignee')),
                  DataColumn(label: Text('Destination')),
                  DataColumn(label: Text('Qty')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Cooly')),
                  DataColumn(label: Text('To Pay')),
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Extra')),
                  DataColumn(label: Text('Charge')),
                  DataColumn(label: Text('Status')),
                ],
                rows: lrs.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final lr = entry.value;
                  final isDelivered = lr.deliveryStatus == 'delivered';

                  return DataRow(
                    onSelectChanged: (_) {
                      // Navigate to LR Details Screen (Screen 6)
                      context.push('/driver/trips/${widget.tripId}/destinations/${lr.destination}/lrs/${lr.lrId}');
                    },
                    cells: [
                      DataCell(Text('$idx')),
                      DataCell(Text(lr.lrNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(lr.consignorName)),
                      DataCell(Text(lr.consigneeName)),
                      DataCell(Text(lr.destination)),
                      DataCell(Text('${lr.qty}')),
                      DataCell(Text('${lr.weight}')),
                      DataCell(Text('₹${lr.cooly.toInt()}')),
                      DataCell(Text('₹${lr.toPay.toInt()}')),
                      DataCell(Text('₹${lr.account.toInt()}')),
                      DataCell(Text('₹${lr.paid.toInt()}')),
                      DataCell(Text(lr.extraCharges)),
                      DataCell(Text('₹${lr.chargeAmount.toInt()}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDelivered ? Colors.green.shade50 : Colors.amber.shade50,
                            border: Border.all(color: isDelivered ? Colors.green : Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDelivered ? '✓ Delivered' : '○ Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDelivered ? Colors.green.shade900 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 5 UI: Bottom Totals & Signature
  Widget _buildBottomTotalsSection(TripModel trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUMMARY CHARGES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.teal)),
            const Divider(),
            _buildInfoRow('Freight Charge', '₹${trip.totals['freight']}', isBold: true),
            _buildInfoRow('Cooly Charges', '₹${trip.totals['coolyCharges']}', isBold: true),
            _buildInfoRow('Total Amount', '₹${trip.totals['totalAmount']}', isBold: true, color: Colors.teal.shade900),
            const SizedBox(height: 12),
            const Text('Remarks:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                hintText: 'Enter notes or observations here...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('For Save Party:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(trip.companyInfo['mobile'] ?? '76676 76776', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Driver Signature', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade50,
                      ),
                      child: Center(
                        child: Text(
                          trip.driverName,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTotalMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}
