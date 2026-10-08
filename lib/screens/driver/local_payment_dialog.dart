import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/local_trip_sheet_model.dart';
import '../../models/lr_model.dart';
import '../../providers/lr_provider.dart';
import '../../services/local_trip_sheet_api_service.dart';

/// Shows the Topay payment dialog for a Local LR.
///
/// Returns the backend-confirmed [LocalPaymentResult] (`is_paid == true`) when
/// the payment succeeded, or null when the dialog was closed without paying.
/// The LR is never marked Paid by this dialog itself.
Future<LocalPaymentResult?> showLocalPaymentDialog({
  required BuildContext context,
  required LRModel lr,
}) {
  return showDialog<LocalPaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LocalPaymentDialog(lr: lr),
  );
}

class _LocalPaymentDialog extends ConsumerStatefulWidget {
  final LRModel lr;
  const _LocalPaymentDialog({required this.lr});

  @override
  ConsumerState<_LocalPaymentDialog> createState() =>
      _LocalPaymentDialogState();
}

class _LocalPaymentDialogState extends ConsumerState<_LocalPaymentDialog> {
  String? _selectedMode;

  // QR state
  bool _qrLoading = false;
  String? _qrError;
  String _qrImageUrl = '';
  Map<String, String> _imageHeaders = const {};
  double? _qrAmount;
  int _qrRequestId = 0; // ignores responses from an outdated selection
  int _imageKey = 0; // bump to force the QR image to reload

  // Submit state
  bool _submitting = false;
  String? _error; // red
  String? _info; // orange (e.g. payment still pending)

  bool get _isQr => _selectedMode != null && isQrPaymentMode(_selectedMode!);
  bool get _isCash => _selectedMode != null && isCashPaymentMode(_selectedMode!);

  /// Amount shown to the driver. For QR the QR API's amount is authoritative.
  double get _amount {
    if (_isQr && _qrAmount != null) return _qrAmount!;
    final lr = widget.lr;
    if (lr.collectableAmount > 0) return lr.collectableAmount;
    return double.tryParse(lr.amount) ?? 0.0;
  }

  bool get _canPay {
    if (_submitting || _selectedMode == null) return false;
    if (_isCash) return true;
    if (_isQr) return !_qrLoading && _qrError == null && _qrImageUrl.isNotEmpty;
    return false;
  }

  void _onModeChanged(String? mode) {
    if (_submitting || mode == null || mode == _selectedMode) return;
    setState(() {
      _selectedMode = mode;
      _error = null;
      _info = null;
      _qrError = null;
      _qrImageUrl = '';
      _qrAmount = null;
      _qrRequestId++;
    });
    if (isQrPaymentMode(mode)) _loadQr();
  }

  Future<void> _loadQr() async {
    final requestId = ++_qrRequestId;
    setState(() {
      _qrLoading = true;
      _qrError = null;
      _error = null;
      _info = null;
    });
    final api = ref.read(localTripSheetApiServiceProvider);
    try {
      final info = await api.fetchLrQrCode(lrId: widget.lr.lrId);
      final url = LocalTripSheetApiService.resolveUrl(info.qrCodeImageUrl);
      final headers = await api.imageHeaders();
      if (!mounted || requestId != _qrRequestId) return;
      setState(() {
        _qrLoading = false;
        _qrAmount = info.amount;
        _imageHeaders = headers;
        _imageKey++;
        if (url.isEmpty) {
          _qrError = 'QR code is not available for this LR.';
          _qrImageUrl = '';
        } else {
          _qrImageUrl = url;
        }
        if (info.isPaid) {
          _info = 'Payment already received. Tap Paid to confirm.';
        }
      });
    } catch (e) {
      if (!mounted || requestId != _qrRequestId) return;
      setState(() {
        _qrLoading = false;
        _qrError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmPaid() async {
    if (!_canPay) return; // also blocks duplicate taps while a request runs
    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    final api = ref.read(localTripSheetApiServiceProvider);
    try {
      final result = await api.checkLrPayment(
        lrId: widget.lr.lrId,
        // Cash: record cash. QR: send only lr_id so the backend verifies the
        // real QR/UPI payment.
        paymentMode: _isCash ? 'Cash' : null,
      );
      if (!mounted) return;
      if (result.isPaid) {
        Navigator.of(context).pop(result);
        return;
      }
      setState(() {
        _submitting = false;
        if (_isQr) {
          _info = 'Payment is not yet received.\n'
              'Please ask the customer to complete the payment.';
        } else {
          _error = result.message.isNotEmpty
              ? result.message
              : 'Payment could not be completed.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _info2(String label, String value) {
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

  Widget _qrSection(BuildContext context) {
    final size = math.min(MediaQuery.of(context).size.width * 0.55, 240.0);

    Widget box(Widget child) => SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        );

    if (_qrLoading) {
      return Center(child: box(const CircularProgressIndicator()));
    }
    if (_qrError != null) {
      return Column(
        children: [
          Text(
            _qrError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _submitting ? null : _loadQr,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_qrImageUrl.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Center(
          child: Container(
            color: Colors.white, // QR needs a light background to be scannable
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.network(
                _qrImageUrl,
                key: ValueKey(_imageKey),
                headers: _imageHeaders,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.grey),
                      const SizedBox(height: 4),
                      const Text(
                        'Could not load QR image',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : _loadQr,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask customer to scan and pay',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lr = widget.lr;
    final modes = lr.allowedPaymentModes;

    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Payment', textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info2('LR Number', lr.lrNumber),
                _info2('Customer', lr.consigneeName),
                _info2('Amount', '₹${_amount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                const Text(
                  'Payment Mode',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                if (modes.isEmpty)
                  const Text(
                    'No payment modes are available for this LR.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMode,
                    isExpanded: true,
                    hint: const Text('Select Payment Mode'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: modes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: _submitting ? null : _onModeChanged,
                  ),
                if (_selectedMode != null && !_isCash && !_isQr) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'This payment mode is not supported in the app.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
                if (_isQr) ...[
                  const SizedBox(height: 12),
                  _qrSection(context),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _info!,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
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
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _canPay ? _confirmPaid : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Paid'),
          ),
        ],
      ),
    );
  }
}