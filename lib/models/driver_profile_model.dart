class DriverProfileModel {
  final String driverId;
  final String driverName;
  final String driverNumber;
  final String licenceNumber;
  final String licenceExpiry;

  DriverProfileModel({
    required this.driverId,
    required this.driverName,
    required this.driverNumber,
    required this.licenceNumber,
    required this.licenceExpiry,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      driverNumber: json['driver_number']?.toString() ?? '',
      licenceNumber: json['licence_number']?.toString() ?? '',
      licenceExpiry: json['licence_expiry']?.toString() ?? '',
    );
  }

  String get safeDriverName => driverName.isNotEmpty ? driverName : 'Not Available';
  String get safeDriverId => driverId.isNotEmpty ? driverId : 'Not Available';
  String get safeDriverNumber => driverNumber.isNotEmpty ? driverNumber : 'Not Available';
  String get safeLicenceNumber => licenceNumber.isNotEmpty ? licenceNumber : 'Not Available';
  String get safeLicenceExpiry => licenceExpiry.isNotEmpty ? licenceExpiry : 'Not Available';
}
