import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/lr_model.dart';
import '../../providers/location_provider.dart';

/// Shows the Local Tripsheet "Delivered" popup.
///
/// [onSubmit] performs the delivery (API call etc.) with the trimmed received
/// person name. It must not throw: it is responsible for its own error /
/// success messaging. The dialog shows a spinner until it completes, then
/// closes itself.
Future<void> showLocalDeliveryDialog({
  required BuildContext context,
  required String localTripNumber,
  required LRModel lr,
  required Future<void> Function(String receivedPerson) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LocalDeliveryDialog(
      localTripNumber: localTripNumber,
      lr: lr,
      onSubmit: onSubmit,
    ),
  );
}

class _LocalDeliveryDialog extends ConsumerStatefulWidget {
  final String localTripNumber;
  final LRModel lr;
  final Future<void> Function(String receivedPerson) onSubmit;

  const _LocalDeliveryDialog({
    required this.localTripNumber,
    required this.lr,
    required this.onSubmit,
  });

  @override
  ConsumerState<_LocalDeliveryDialog> createState() =>
      _LocalDeliveryDialogState();
}

class _LocalDeliveryDialogState extends ConsumerState<_LocalDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _personController;
  bool _isSubmitting = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // API-provided received_person is the initial value; driver may edit it.
    _personController = TextEditingController(text: widget.lr.receivedPerson);
  }

  @override
  void dispose() {
    _personController.dispose();
    super.dispose();
  }

  /// Re-applies the same 2 KM rule as the Delivered button right before
  /// submitting, so a stale UI state can never bypass it.
  /// Returns an error message, or null when delivery is allowed.
  String? _checkDistance() {
    final lr = widget.lr;
    if (lr.receiverLat == 0.0 || lr.receiverLng == 0.0) {
      return 'Destination location unavailable.';
    }
    final current = ref.read(driverCurrentLocationProvider);
    if (current == null) {
      return 'Unable to get your current location. Please enable GPS and try again.';
    }
    try {
      final meters = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        lr.receiverLat,
        lr.receiverLng,
      );
      if (meters > 2000.0) {
        return 'You must be within 2 km of the destination to mark this LR as Delivered.';
      }
    } catch (_) {
      return 'Could not calculate your distance to the destination. Please try again.';
    }
    return null;
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final distanceError = _checkDistance();
    if (distanceError != null) {
      setState(() => _locationError = distanceError);
      return;
    }

    setState(() {
      _locationError = null;
      _isSubmitting = true;
    });
    try {
      await widget.onSubmit(_personController.text.trim());
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lr = widget.lr;
    final mobile =
        lr.receivedMobileNumber.isNotEmpty ? lr.receivedMobileNumber : lr.consigneePhone;

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: const Text('Delivery Confirmation'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('Local Trip Sheet ID', widget.localTripNumber),
                _info('LR ID', lr.lrNumber),
                const SizedBox(height: 4),
                const Text(
                  'Received Person',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _personController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter received person name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 13),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Please enter the received person name'
                      : null,
                ),
                const SizedBox(height: 8),
                _info('Received Mobile Number', mobile),
                _info('Delivery PIN', lr.deliveryPin),
                _info('Payment Mode', lr.paymentMode),
                _info('Collected Amount', lr.collectableAmount.toStringAsFixed(2)),
                if (_locationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _locationError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
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
      ),
    );
  }
}
