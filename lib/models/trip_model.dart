class TripModel {
  final String tripId;
  final String tripNo;
  final DateTime date;
  final String vehicleNumber;
  final String vehicleName;
  final String driverUid;
  final String driverName;
  final String driverMobile;
  final String from;
  final List<String> toStops;
  final String status; // "PENDING" | "STARTED" | "COMPLETED"
  final String acknowledgementStatus; // "Pending" | "Accepted" | "Rejected"
  final String gpsStatus; // "Active" | "Disabled"
  final int totalLR;
  final int pendingLR;
  final int deliveredLR;
  final int cancelledLR;
  final List<String> branches;
  final Map<String, dynamic> totals; 
  // totals format: { amount, weight, cooly, toPay, paid, account, freight, coolyCharges, totalAmount }
  final String remarks;
  final Map<String, String> companyInfo;

  TripModel({
    required this.tripId,
    required this.tripNo,
    required this.date,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.driverUid,
    required this.driverName,
    required this.driverMobile,
    required this.from,
    required this.toStops,
    required this.status,
    this.acknowledgementStatus = 'Pending',
    required this.gpsStatus,
    required this.totalLR,
    required this.pendingLR,
    required this.deliveredLR,
    required this.cancelledLR,
    required this.branches,
    required this.totals,
    required this.remarks,
    required this.companyInfo,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['tripId'] ?? '',
      tripNo: json['tripNo'] ?? '',
      date: json['date'] != null 
          ? (json['date'] is String 
              ? DateTime.parse(json['date']) 
              : (json['date'] as DateTime))
          : DateTime.now(),
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      driverUid: json['driverUid'] ?? '',
      driverName: json['driverName'] ?? '',
      driverMobile: json['driverMobile'] ?? '',
      from: json['from'] ?? '',
      toStops: List<String>.from(json['toStops'] ?? []),
      status: json['status'] ?? 'PENDING',
      acknowledgementStatus: json['acknowledgementStatus'] ?? 'Pending',
      gpsStatus: json['gpsStatus'] ?? 'Active',
      totalLR: json['totalLR'] ?? 0,
      pendingLR: json['pendingLR'] ?? 0,
      deliveredLR: json['deliveredLR'] ?? 0,
      cancelledLR: json['cancelledLR'] ?? 0,
      branches: List<String>.from(json['branches'] ?? []),
      totals: Map<String, dynamic>.from(json['totals'] ?? {}),
      remarks: json['remarks'] ?? '',
      companyInfo: Map<String, String>.from(json['companyInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripNo': tripNo,
      'date': date.toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'vehicleName': vehicleName,
      'driverUid': driverUid,
      'driverName': driverName,
      'driverMobile': driverMobile,
      'from': from,
      'toStops': toStops,
      'status': status,
      'acknowledgementStatus': acknowledgementStatus,
      'gpsStatus': gpsStatus,
      'totalLR': totalLR,
      'pendingLR': pendingLR,
      'deliveredLR': deliveredLR,
      'cancelledLR': cancelledLR,
      'branches': branches,
      'totals': totals,
      'remarks': remarks,
      'companyInfo': companyInfo,
    };
  }

  TripModel copyWith({
    String? status,
    String? acknowledgementStatus,
    int? pendingLR,
    int? deliveredLR,
    String? gpsStatus,
  }) {
    return TripModel(
      tripId: tripId,
      tripNo: tripNo,
      date: date,
      vehicleNumber: vehicleNumber,
      vehicleName: vehicleName,
      driverUid: driverUid,
      driverName: driverName,
      driverMobile: driverMobile,
      from: from,
      toStops: toStops,
      status: status ?? this.status,
      acknowledgementStatus: acknowledgementStatus ?? this.acknowledgementStatus,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      totalLR: totalLR,
      pendingLR: pendingLR ?? this.pendingLR,
      deliveredLR: deliveredLR ?? this.deliveredLR,
      cancelledLR: cancelledLR,
      branches: branches,
      totals: totals,
      remarks: remarks,
      companyInfo: companyInfo,
    );
  }
}