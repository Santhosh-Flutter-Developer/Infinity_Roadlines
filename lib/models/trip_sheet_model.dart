import 'trip_model.dart';

class TripSheetModel {
  final String tripSheetId;
  final String tripNumber;
  final DateTime tripDate;
  final String vehicleId;
  final String vehicleNumber;
  final String driverId;
  final String driverName;
  final String driverNumber;
  final String fromBranchId;
  final String fromBranchName;
  final List<String> toBranchIds;
  final List<String> toBranchNames;
  final String destinationId;
  final String destinationName;
  final int lrCount;
  final List<String> lrEntryIds;
  final String helperName;
  final String vehicleRent;
  final String isTripsheetEntry;
  final String remarks;

  TripSheetModel({
    required this.tripSheetId,
    required this.tripNumber,
    required this.tripDate,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverId,
    required this.driverName,
    required this.driverNumber,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchIds,
    required this.toBranchNames,
    required this.destinationId,
    required this.destinationName,
    required this.lrCount,
    required this.lrEntryIds,
    required this.helperName,
    required this.vehicleRent,
    required this.isTripsheetEntry,
    required this.remarks,
  });

  factory TripSheetModel.fromJson(Map<String, dynamic> json) {
    return TripSheetModel(
      tripSheetId: json['trip_sheet_id']?.toString() ?? '',
      tripNumber: json['trip_number']?.toString() ?? '',
      tripDate: json['trip_date'] != null
          ? (json['trip_date'] is String
              ? DateTime.parse(json['trip_date'])
              : (json['trip_date'] as DateTime))
          : DateTime.now(),
      vehicleId: json['vehicle_id']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      driverNumber: json['driver_number']?.toString() ?? '',
      fromBranchId: json['from_branch_id']?.toString() ?? '',
      fromBranchName: json['from_branch_name']?.toString() ?? '',
      toBranchIds: json['to_branch_ids'] != null
          ? List<String>.from(json['to_branch_ids'])
          : [],
      toBranchNames: json['to_branch_names'] != null
          ? List<String>.from(json['to_branch_names'])
          : [],
      destinationId: json['destination_id']?.toString() ?? '',
      destinationName: json['destination_name']?.toString() ?? '',
      lrCount: json['lr_count'] is int
          ? json['lr_count']
          : int.tryParse(json['lr_count']?.toString() ?? '0') ?? 0,
      lrEntryIds: json['lr_entry_ids'] != null
          ? List<String>.from(json['lr_entry_ids'])
          : [],
      helperName: json['helper_name']?.toString() ?? '',
      vehicleRent: json['vehicle_rent']?.toString() ?? '',
      isTripsheetEntry: json['is_tripsheet_entry']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_sheet_id': tripSheetId,
      'trip_number': tripNumber,
      'trip_date': tripDate.toIso8601String(),
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_number': driverNumber,
      'from_branch_id': fromBranchId,
      'from_branch_name': fromBranchName,
      'to_branch_ids': toBranchIds,
      'to_branch_names': toBranchNames,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'lr_count': lrCount,
      'lr_entry_ids': lrEntryIds,
      'helper_name': helperName,
      'vehicle_rent': vehicleRent,
      'is_tripsheet_entry': isTripsheetEntry,
      'remarks': remarks,
    };
  }

  TripModel toTripModel() {
    return TripModel(
      tripId: tripSheetId,
      tripNo: tripNumber,
      date: tripDate,
      vehicleNumber: vehicleNumber,
      vehicleName: 'Sakthivel Travels',
      driverUid: driverId,
      driverName: driverName,
      driverMobile: driverNumber,
      from: fromBranchName,
      toStops: toBranchNames.isNotEmpty ? toBranchNames : [destinationName],
      status: isTripsheetEntry == '1' ? 'STARTED' : 'PENDING',
      gpsStatus: 'Active',
      totalLR: lrCount,
      pendingLR: lrCount,
      deliveredLR: 0,
      cancelledLR: 0,
      branches: [fromBranchName, ...toBranchNames],
      totals: {
        'amount': 0.0,
        'weight': 0.0,
        'cooly': 0.0,
        'toPay': 0.0,
        'paid': 0.0,
        'account': 0.0,
        'freight': 0.0,
        'coolyCharges': 0.0,
        'totalAmount': 0.0,
      },
      remarks: remarks,
      companyInfo: {
        'name': 'Infinity Roadlines',
        'address': 'Sivakasi, Tamil Nadu',
        'mobile': '9876543210',
        'logoUrl': '',
      },
    );
  }
}
