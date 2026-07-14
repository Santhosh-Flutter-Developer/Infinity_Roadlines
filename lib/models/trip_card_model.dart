class TripCardModel {
  final String tripCardId;
  final String tripCardNumber;
  final DateTime entryDate;
  final String vehicleId;
  final String vehicleNumber;
  final String driverId;
  final String driverName;
  final String fromBranch;
  final String toBranch;
  final String quantity;
  final String unitName;
  final String driverSalary;

  TripCardModel({
    required this.tripCardId,
    required this.tripCardNumber,
    required this.entryDate,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverId,
    required this.driverName,
    required this.fromBranch,
    required this.toBranch,
    required this.quantity,
    required this.unitName,
    required this.driverSalary,
  });

  factory TripCardModel.fromJson(Map<String, dynamic> json) {
    return TripCardModel(
      tripCardId: json['trip_card_id']?.toString() ?? '',
      tripCardNumber: json['trip_card_number']?.toString() ?? '',
      entryDate: json['entry_date'] != null
          ? (json['entry_date'] is String
              ? DateTime.tryParse(json['entry_date']) ?? DateTime.now()
              : (json['entry_date'] as DateTime))
          : DateTime.now(),
      vehicleId: json['vehicle_id']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      fromBranch: json['from_branch']?.toString() ?? '',
      toBranch: json['to_branch']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      driverSalary: json['driver_salary']?.toString() ?? '',
    );
  }
}
