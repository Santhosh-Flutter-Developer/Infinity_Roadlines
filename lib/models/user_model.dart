class UserModel {
  final String uid;
  final String role; // "driver" | "admin"
  final String name;
  final String username;
  final String phone;
  final String? vehicleNumber;
  final String status; // "online" | "offline" | "driving" | "stopped" | "gps_disabled"
  final Map<String, dynamic>? lastLocation; // { lat, lng, updatedAt }
  final double battery;
  final bool internetConnected;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.username,
    required this.phone,
    this.vehicleNumber,
    required this.status,
    this.lastLocation,
    required this.battery,
    required this.internetConnected,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      vehicleNumber: json['vehicleNumber'],
      status: json['status'] ?? 'offline',
      lastLocation: json['lastLocation'] != null ? Map<String, dynamic>.from(json['lastLocation']) : null,
      battery: (json['battery'] as num?)?.toDouble() ?? 100.0,
      internetConnected: json['internetConnected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'username': username,
      'phone': phone,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'lastLocation': lastLocation,
      'battery': battery,
      'internetConnected': internetConnected,
    };
  }

  UserModel copyWith({
    String? status,
    Map<String, dynamic>? lastLocation,
    double? battery,
    bool? internetConnected,
  }) {
    return UserModel(
      uid: uid,
      role: role,
      name: name,
      username: username,
      phone: phone,
      vehicleNumber: vehicleNumber,
      status: status ?? this.status,
      lastLocation: lastLocation ?? this.lastLocation,
      battery: battery ?? this.battery,
      internetConnected: internetConnected ?? this.internetConnected,
    );
  }
}
