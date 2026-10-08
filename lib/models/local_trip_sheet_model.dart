import 'lr_model.dart';
import 'trip_sheet_model.dart';

String _str(dynamic v) => v?.toString() ?? '';

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

String _firstNonEmpty(List<dynamic> values) {
  for (final v in values) {
    final text = v?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

bool? _boolOrNull(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final t = v.toString().trim().toLowerCase();
  if (t == 'true' || t == '1' || t == 'yes') return true;
  if (t == 'false' || t == '0' || t == 'no') return false;
  return null;
}

List<String> _stringList(dynamic v) {
  if (v is! List) return const [];
  return v
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

double _double(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

/// One row of `get_local_trip_sheet_list.php`.
class LocalTripSheet {
  final int id;
  final String localTripSheetId;
  final String localTripNumber;
  final String tripDate;
  final String branchName;
  final String vehicleNumberName;
  final String driverName;
  final String driverNumber;
  final String deliveryArea;
  final String destinationName;
  final String fromBranchId;
  final String vehicleId;
  final int totalLrs;
  final int totalPackages;
  final String totalWeight;
  final String totalTopayAmount;
  final int deliveredLrsCount;
  final int pendingLrsCount;
  final String status;

  LocalTripSheet({
    required this.id,
    required this.localTripSheetId,
    required this.localTripNumber,
    required this.tripDate,
    required this.branchName,
    required this.vehicleNumberName,
    required this.driverName,
    required this.driverNumber,
    required this.deliveryArea,
    required this.destinationName,
    required this.fromBranchId,
    required this.vehicleId,
    required this.totalLrs,
    required this.totalPackages,
    required this.totalWeight,
    required this.totalTopayAmount,
    required this.deliveredLrsCount,
    required this.pendingLrsCount,
    required this.status,
  });

  factory LocalTripSheet.fromJson(Map<String, dynamic> json) {
    return LocalTripSheet(
      id: _int(json['id']),
      localTripSheetId: _str(json['local_trip_sheet_id']),
      localTripNumber: _str(json['local_trip_number']),
      tripDate: _str(json['trip_date']),
      branchName: _firstNonEmpty([json['branch_name'], json['from_branch_name']]),
      vehicleNumberName: _str(json['vehicle_number_name']),
      driverName: _str(json['driver_name']),
      driverNumber: _str(json['driver_number']),
      deliveryArea: _str(json['delivery_area']),
      // The list API sends the label in `destination_name` / `destination`;
      // `delivery_area` can be empty, so it is only the last fallback.
      destinationName: _firstNonEmpty([
        json['destination_name'],
        json['destination'],
        json['delivery_area'],
      ]),
      fromBranchId: _str(json['from_branch_id']),
      vehicleId: _str(json['vehicle_id']),
      totalLrs: _int(json['total_lrs']),
      totalPackages: _int(json['total_packages']),
      totalWeight: _str(json['total_weight']),
      totalTopayAmount: _str(json['total_topay_amount']),
      deliveredLrsCount: _int(json['delivered_lrs_count']),
      pendingLrsCount: _int(json['pending_lrs_count']),
      status: json['status'] == null ? 'Dispatched' : _str(json['status']),
    );
  }

  /// Maps this Local tripsheet onto the existing [TripSheetModel] so the
  /// existing providers and the existing Tripsheet card UI render it
  /// unchanged. The `local_trip_number` is used as the tripsheet id because
  /// every Local API after the list call is keyed by it.
  TripSheetModel toTripSheetModel({required String driverId}) {
    return TripSheetModel(
      tripSheetId: localTripNumber,
      tripNumber: localTripNumber,
      tripDate: DateTime.tryParse(tripDate) ?? DateTime.now(),
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumberName,
      driverId: driverId,
      driverName: driverName,
      driverNumber: driverNumber,
      fromBranchId: fromBranchId,
      fromBranchName: branchName,
      toBranchIds: const [],
      toBranchNames: destinationName.isNotEmpty ? [destinationName] : const [],
      destinationId: '',
      destinationName: destinationName,
      lrCount: totalLrs,
      lrEntryIds: const [],
      helperName: '',
      vehicleRent: '',
      isTripsheetEntry: '',
      remarks: '',
      tripStatus: status,
      acknowledgementStatus: 'Accepted',
    );
  }
}

/// One page of `get_local_trip_sheet_list.php`.
class LocalTripSheetPage {
  final List<LocalTripSheet> items;
  final int totalCount;
  final int pageNumber;

  /// 0 when the API did not send `total_pages`.
  final int totalPages;

  LocalTripSheetPage({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.totalPages,
  });
}

/// One LR inside `get_local_trip_sheet_details.php`.
class LocalTripSheetLR {
  final String lrId;
  final String lrEntryId;
  final String lrNumber;
  final String lrDate;
  final String parentTripNumber;
  final String consignorName;
  final String consignorMobile;
  final String consigneeName;
  final String consigneeMobile;
  final String consigneeAddress;
  final String billType;
  final double totalAmount;
  final double collectableAmount;
  final String quantity;
  final String unitName;
  final String weight;
  final String deliveryPin;
  final int isCleared;
  final int pinNotProvided;
  final int pinVerified;
  final String paymentMode;
  final String deliveryStatus;
  final String receivedPerson;
  final String receivedMobileNumber;
  final String receivedIdentification;
  final double destinationLat;
  final double destinationLng;
  final bool isTopay;
  final String paymentStatus;
  final String paymentModeName;
  final List<String> allowedPaymentModes;
  final String razorpayPaymentId;
  final String razorpayQrId;
  final String razorpayQrUrl;
  final String qrCodeImageUrl;

  LocalTripSheetLR({
    required this.lrId,
    required this.lrEntryId,
    required this.lrNumber,
    required this.lrDate,
    required this.parentTripNumber,
    required this.consignorName,
    required this.consignorMobile,
    required this.consigneeName,
    required this.consigneeMobile,
    required this.consigneeAddress,
    required this.billType,
    required this.totalAmount,
    required this.collectableAmount,
    required this.quantity,
    required this.unitName,
    required this.weight,
    required this.deliveryPin,
    required this.isCleared,
    required this.pinNotProvided,
    required this.pinVerified,
    required this.paymentMode,
    required this.deliveryStatus,
    required this.receivedPerson,
    required this.receivedMobileNumber,
    required this.receivedIdentification,
    required this.destinationLat,
    required this.destinationLng,
    required this.isTopay,
    required this.paymentStatus,
    required this.paymentModeName,
    required this.allowedPaymentModes,
    required this.razorpayPaymentId,
    required this.razorpayQrId,
    required this.razorpayQrUrl,
    required this.qrCodeImageUrl,
  });

  factory LocalTripSheetLR.fromJson(Map<String, dynamic> json) {
    return LocalTripSheetLR(
      lrId: _str(json['lr_id']),
      lrEntryId: _str(json['lr_entry_id']),
      lrNumber: _firstNonEmpty([json['lr_number'], json['lr_no']]),
      lrDate: _str(json['lr_date']),
      parentTripNumber: _str(json['parent_trip_number']),
      consignorName: _str(json['consignor_name']),
      consignorMobile: _str(json['consignor_mobile']),
      consigneeName: _str(json['consignee_name']),
      consigneeMobile: _str(json['consignee_mobile']),
      consigneeAddress: _str(json['consignee_address']),
      billType: _str(json['bill_type']),
      totalAmount: _double(json['total_amount']),
      collectableAmount: _double(json['collectable_amount']),
      quantity: _str(json['quantity']),
      unitName: _str(json['unit_name']),
      weight: _str(json['weight']),
      deliveryPin: _str(json['delivery_pin']),
      isCleared: _int(json['is_cleared']),
      pinNotProvided: _int(json['pin_not_provided']),
      pinVerified: _int(json['pin_verified']),
      paymentMode: _str(json['payment_mode']),
      deliveryStatus:
          json['delivery_status'] == null ? 'Pending' : _str(json['delivery_status']),
      receivedPerson: _str(json['received_person']),
      receivedMobileNumber: _str(json['received_mobile_number']),
      receivedIdentification: _str(json['received_identification']),
      // Same coordinate keys the General LR list uses, so the existing
      // 2 KM rule applies unchanged. 0.0 when the API doesn't send them.
      destinationLat: _double(json['destination_latitude'] ?? json['receiver_lat']),
      destinationLng: _double(json['destination_longitude'] ?? json['receiver_lng']),
      // `is_topay` is authoritative; only when it is missing fall back to bill type.
      isTopay: _boolOrNull(json['is_topay']) ??
          _str(json['bill_type']).trim().toLowerCase() == 'topay',
      paymentStatus: _firstNonEmpty([json['payment_status']]).isEmpty
          ? 'Pending'
          : _firstNonEmpty([json['payment_status']]),
      paymentModeName: _str(json['payment_mode_name']),
      allowedPaymentModes: _stringList(json['allowed_payment_modes']),
      razorpayPaymentId: _str(json['razorpay_payment_id']),
      razorpayQrId: _str(json['razorpay_qr_id']),
      razorpayQrUrl: _str(json['razorpay_qr_url']),
      qrCodeImageUrl: _str(json['qr_code_image_url']),
    );
  }

  /// Maps this Local LR into the existing [LRModel] so the existing LR UI
  /// (LrListScreen) renders it.
  LRModel toLRModel() {
    return LRModel(
      lrId: lrId,
      lrNumber: lrNumber,
      entryDate: lrDate,
      consignorName: consignorName,
      consigneeName: consigneeName,
      quantity: quantity,
      unitName: unitName,
      amount: totalAmount.toStringAsFixed(2),
      status: deliveryStatus,
      billType: billType,
      weight: weight,
      receiverLat: destinationLat,
      receiverLng: destinationLng,
      consigneePhone: consigneeMobile,
      consignorPhone: consignorMobile,
      address: consigneeAddress,
      // Local-only extras (empty/default for General LRs).
      parentTripNumber: parentTripNumber,
      deliveryPin: deliveryPin,
      paymentMode: paymentMode,
      collectableAmount: collectableAmount,
      pinNotProvided: pinNotProvided,
      receivedPerson: receivedPerson,
      receivedMobileNumber: receivedMobileNumber,
      receivedIdentification: receivedIdentification,
      isTopay: isTopay,
      paymentStatus: paymentStatus,
      paymentModeName: paymentModeName,
      allowedPaymentModes: allowedPaymentModes,
      razorpayPaymentId: razorpayPaymentId,
      razorpayQrId: razorpayQrId,
      razorpayQrUrl: razorpayQrUrl,
      qrCodeImageUrl: qrCodeImageUrl,
    );
  }
}

/// Parsed `get_local_trip_sheet_details.php` data.
class LocalTripSheetDetails {
  final String localTripNumber;
  final String tripDate;
  final String vehicleNumberName;
  final String driverName;
  final String deliveryArea;
  final int totalLrsCount;
  final int deliveredLrsCount;
  final int pendingLrsCount;
  final double totalTopayPendingAmount;
  final List<LocalTripSheetLR> lrs;

  LocalTripSheetDetails({
    required this.localTripNumber,
    required this.tripDate,
    required this.vehicleNumberName,
    required this.driverName,
    required this.deliveryArea,
    required this.totalLrsCount,
    required this.deliveredLrsCount,
    required this.pendingLrsCount,
    required this.totalTopayPendingAmount,
    required this.lrs,
  });

  factory LocalTripSheetDetails.fromJson(Map<String, dynamic> json) {
    final rawLrs = json['lrs'];
    final lrs = <LocalTripSheetLR>[];
    if (rawLrs is List) {
      for (final item in rawLrs) {
        if (item is Map<String, dynamic>) {
          lrs.add(LocalTripSheetLR.fromJson(item));
        }
      }
    }
    return LocalTripSheetDetails(
      localTripNumber: _str(json['local_trip_number']),
      tripDate: _str(json['trip_date']),
      vehicleNumberName: _str(json['vehicle_number_name']),
      driverName: _str(json['driver_name']),
      deliveryArea: _str(json['delivery_area']),
      totalLrsCount: _int(json['total_lrs_count'] ?? json['total_lrs']),
      deliveredLrsCount: _int(json['delivered_lrs_count']),
      pendingLrsCount: _int(json['pending_lrs_count']),
      totalTopayPendingAmount: _double(
          json['total_topay_pending_amount'] ?? json['total_topay_pending']),
      lrs: lrs,
    );
  }

  LocalTripSheetDetails copyWithCounts({
    required int deliveredLrsCount,
    required int pendingLrsCount,
  }) {
    return LocalTripSheetDetails(
      localTripNumber: localTripNumber,
      tripDate: tripDate,
      vehicleNumberName: vehicleNumberName,
      driverName: driverName,
      deliveryArea: deliveryArea,
      totalLrsCount: totalLrsCount,
      deliveredLrsCount: deliveredLrsCount,
      pendingLrsCount: pendingLrsCount,
      totalTopayPendingAmount: totalTopayPendingAmount,
      lrs: lrs,
    );
  }
}

/// Parsed `update_local_lr_delivery.php` success payload.
class LocalDeliveryResult {
  final String message;
  final String lrNumber;
  final String status;
  final bool allLrsDelivered;

  LocalDeliveryResult({
    required this.message,
    required this.lrNumber,
    required this.status,
    required this.allLrsDelivered,
  });

  factory LocalDeliveryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final all = map['all_lrs_delivered'];
    return LocalDeliveryResult(
      message: json['message']?.toString() ?? 'LR marked as delivered.',
      lrNumber: _str(map['lr_number']),
      status: map['status'] == null ? 'Delivered' : _str(map['status']),
      // Only a real `true` triggers the tripsheet status call.
      allLrsDelivered: all == true || all == 1 || all == '1' || all == 'true',
    );
  }
}

/// Outcome of a full local delivery (LR call + optional tripsheet status call).
class LocalDeliveryOutcome {
  final LocalDeliveryResult result;

  /// True when `all_lrs_delivered == true` and the tripsheet status call succeeded.
  final bool tripSheetMarkedDelivered;

  /// Non-null when the LR delivery succeeded but the tripsheet status call failed.
  final String? tripStatusError;

  LocalDeliveryOutcome({
    required this.result,
    required this.tripSheetMarkedDelivered,
    this.tripStatusError,
  });
}

/// Parsed `check_lr_payment_status.php` response.
class LocalPaymentResult {
  final bool isPaid;
  final String paymentStatus;
  final String paymentMode;
  final String razorpayPaymentId;
  final double? amount;
  final String message;

  LocalPaymentResult({
    required this.isPaid,
    required this.paymentStatus,
    required this.paymentMode,
    required this.razorpayPaymentId,
    required this.amount,
    required this.message,
  });

  factory LocalPaymentResult.fromJson(Map<String, dynamic> json) {
    // Fields are top-level; tolerate them being nested in `data`.
    final nested = json['data'];
    final src = json['is_paid'] == null && nested is Map<String, dynamic>
        ? nested
        : json;
    final paid = _boolOrNull(src['is_paid']) ?? false;
    final status = _str(src['payment_status']);
    return LocalPaymentResult(
      // Only an explicit true counts as paid.
      isPaid: paid,
      paymentStatus: status.isEmpty ? (paid ? 'Paid' : 'Pending') : status,
      paymentMode: _str(src['payment_mode']),
      razorpayPaymentId: _str(src['razorpay_payment_id']),
      amount: src['amount'] == null ? null : _double(src['amount']),
      message: _str(json['message']),
    );
  }
}

/// Parsed `get_lr_qr_code.php` data.
class LocalQrInfo {
  final double? amount;
  final bool isPaid;
  final String qrCodeImageUrl;

  LocalQrInfo({
    required this.amount,
    required this.isPaid,
    required this.qrCodeImageUrl,
  });

  factory LocalQrInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final src = data is Map<String, dynamic> ? data : json;
    return LocalQrInfo(
      amount: src['amount'] == null ? null : _double(src['amount']),
      isPaid: _boolOrNull(src['is_paid']) ?? false,
      qrCodeImageUrl: _str(src['qr_code_image_url']),
    );
  }
}

/// True when a payment-mode label means the QR/UPI flow
/// ("QR Code", "QR Code / UPI", "UPI", ...).
bool isQrPaymentMode(String mode) {
  final m = mode.toLowerCase();
  return m.contains('qr') || m.contains('upi');
}

bool isCashPaymentMode(String mode) => mode.trim().toLowerCase() == 'cash';