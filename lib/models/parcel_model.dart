class ParcelModel {
  final String parcelId;
  final String branch;
  final String status; // "pending" | "received" | "reached" | "completed"
  final String? tripId;

  ParcelModel({
    required this.parcelId,
    required this.branch,
    required this.status,
    this.tripId,
  });

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      parcelId: json['parcelId'] ?? '',
      branch: json['branch'] ?? '',
      status: json['status'] ?? 'pending',
      tripId: json['tripId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parcelId': parcelId,
      'branch': branch,
      'status': status,
      'tripId': tripId,
    };
  }

  ParcelModel copyWith({
    String? status,
    String? tripId,
  }) {
    return ParcelModel(
      parcelId: parcelId,
      branch: branch,
      status: status ?? this.status,
      tripId: tripId ?? this.tripId,
    );
  }
}
