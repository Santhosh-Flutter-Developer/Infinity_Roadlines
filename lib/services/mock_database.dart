import 'dart:async';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/lr_model.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal() {
    _initData();
  }

  final _usersController = StreamController<List<UserModel>>.broadcast();
  final _tripsController = StreamController<List<TripModel>>.broadcast();
  final _lrsController = StreamController<List<LRModel>>.broadcast();

  final List<UserModel> _users = [];
  final List<TripModel> _trips = [];
  final List<LRModel> _lrs = [];

  Stream<List<UserModel>> get usersStream => _usersController.stream;
  Stream<List<TripModel>> get tripsStream => _tripsController.stream;
  Stream<List<LRModel>> get lrsStream => _lrsController.stream;

  void _initData() {
    _users.addAll([
      UserModel(
        uid: 'driver_kumar',
        role: 'driver',
        name: 'Kumar Swamy',
        username: 'kumar',
        phone: '8988896785',
        vehicleNumber: 'TN67 CD 5678',
        status: 'online',
        lastLocation: {'lat': 9.4526, 'lng': 77.8016, 'updatedAt': DateTime.now().toIso8601String()},
        battery: 90,
        internetConnected: true,
      ),
      UserModel(
        uid: 'driver_mari',
        role: 'driver',
        name: 'Mari Muthu',
        username: 'mari',
        phone: '+91 98765 43211',
        vehicleNumber: 'TN-67-AP-5678',
        status: 'driving',
        lastLocation: {'lat': 9.9252, 'lng': 78.1198, 'updatedAt': DateTime.now().toIso8601String()},
        battery: 92,
        internetConnected: true,
      ),
      UserModel(
        uid: 'admin_vinayagam',
        role: 'admin',
        name: 'Vinayagam Dev',
        username: 'admin',
        phone: '+91 99999 88888',
        status: 'online',
        battery: 98,
        internetConnected: true,
      ),
    ]);

    _trips.addAll([
      TripModel(
        tripId: 'trip_101',
        tripNo: 'TS005/26-27',
        date: DateTime(2026, 7, 6),
        vehicleNumber: 'TN67 CD 5678',
        vehicleName: 'Sakthivel Travels',
        driverUid: 'driver_kumar',
        driverName: 'Kumar',
        driverMobile: '8988896785',
        from: 'Sivakasi',
        toStops: ['Karur', 'Erode', 'Tirupur', 'Coimbatore'],
        status: 'STARTED',
        gpsStatus: 'Active',
        totalLR: 6,
        pendingLR: 4,
        deliveredLR: 2,
        cancelledLR: 0,
        branches: ['Sivakasi', 'Karur', 'Erode', 'Tirupur', 'Coimbatore'],
        totals: {
          'amount': 135723.0,
          'weight': 47.0,
          'cooly': 1643.0,
          'toPay': 54310.0,
          'paid': 0.0, // Match screenshot: Paid: 0
          'account': 0.0,
          'freight': 190033.0,
          'coolyCharges': 1643.0,
          'totalAmount': 191676.0,
        },
        remarks: 'Standard transit route. Drive safely.',
        companyInfo: {
          'name': 'Infinity Roadlines',
          'address': 'Sivakasi, Tamil Nadu',
          'mobile': '9876543210',
          'logoUrl': '',
        },
      ),
      TripModel(
        tripId: 'trip_102',
        tripNo: 'TS006/26-27',
        date: DateTime(2026, 7, 5),
        vehicleNumber: 'TN-67-AP-5678',
        vehicleName: 'Vetrivel Transport',
        driverUid: 'driver_mari',
        driverName: 'Mari',
        driverMobile: '9988776655',
        from: 'Virudhunagar',
        toStops: ['Madurai', 'Trichy'],
        status: 'STARTED',
        gpsStatus: 'Active',
        totalLR: 3,
        pendingLR: 3,
        deliveredLR: 0,
        cancelledLR: 0,
        branches: ['Virudhunagar', 'Madurai', 'Trichy'],
        totals: {
          'amount': 79500.0,
          'weight': 32.0,
          'cooly': 950.0,
          'toPay': 29500.0,
          'paid': 50000.0,
          'account': 0.0,
          'freight': 80450.0,
          'coolyCharges': 950.0,
          'totalAmount': 80450.0,
        },
        remarks: 'Handle fragile goods carefully.',
        companyInfo: {
          'name': 'Infinity Roadlines',
          'address': 'Sivakasi, Tamil Nadu',
          'mobile': '9876543210',
          'logoUrl': '',
        },
      ),
    ]);

    _lrs.addAll([
      // Trip 101 - Karur Stop
      LRModel(
        lrId: 'lr_1',
        lrNumber: 'LR038/26-27',
        consignorName: 'Abi',
        consignorPhone: '76399 18567',
        consigneeName: 'Abiram',
        consigneePhone: '98137 41384',
        destination: 'Karur',
        address: '12, Kovai Main Road, Karur',
        qty: 50,
        weight: 12.0,
        cooly: 350.0,
        toPay: 15400.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'delivered', // 2 Delivered in Karur
        receiverLat: 10.9602,
        receiverLng: 78.0770,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
        deliveredLat: 10.9602,
        deliveredLng: 78.0770,
      ),
      LRModel(
        lrId: 'lr_2',
        lrNumber: 'LR039/26-27',
        consignorName: 'Rajan Printers',
        consignorPhone: '94432 67890',
        consigneeName: 'Velavan Retail Bar',
        consigneePhone: '94432 00000',
        destination: 'Karur',
        address: '88, Bus Stand Outer Road, Karur',
        qty: 25,
        weight: 5.0,
        cooly: 150.0,
        toPay: 8500.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'delivered', // 2 Delivered in Karur
        receiverLat: 10.9620,
        receiverLng: 78.0750,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
        deliveredLat: 10.9620,
        deliveredLng: 78.0750,
      ),
      // Trip 101 - Erode Stop
      LRModel(
        lrId: 'lr_3',
        lrNumber: 'LR044/26-27',
        consignorName: 'Abi-76399 18567',
        consignorPhone: '76399 18567',
        consigneeName: 'Abiram-98137 41384',
        consigneePhone: '98137 41384',
        destination: 'Erode',
        address: '45, Brough Road, Erode',
        qty: 50,
        weight: 0.0,
        cooly: 0.0,
        toPay: 1750.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 11.3412,
        receiverLng: 77.7180,
      ),
      LRModel(
        lrId: 'lr_4',
        lrNumber: 'LR041/26-27',
        consignorName: 'Madhan-79857 78967',
        consignorPhone: '79857 78967',
        consigneeName: 'Meera-78967 12345',
        consigneePhone: '78967 12345',
        destination: 'Erode',
        address: '102, Netaji Road, Erode',
        qty: 20,
        weight: 0.0,
        cooly: 0.0,
        toPay: 0.0,
        account: 0.0,
        paid: 4000.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 11.3395,
        receiverLng: 77.7160,
      ),
      LRModel(
        lrId: 'lr_5',
        lrNumber: 'LR040/26-27',
        consignorName: 'King-89012 34567',
        consignorPhone: '89012 34567',
        consigneeName: 'Queen-88991 76543',
        consigneePhone: '88991 76543',
        destination: 'Erode',
        address: '22, Central Market, Erode',
        qty: 28,
        weight: 0.0,
        cooly: 0.0,
        toPay: 19430.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: 'Packing Charges',
        chargeAmount: 670.0,
        deliveryStatus: 'delivered', // Matches PDF where one is delivered
        receiverLat: 11.3430,
        receiverLng: 77.7200,
        deliveredAt: DateTime.now().subtract(const Duration(minutes: 30)),
        deliveredLat: 11.3430,
        deliveredLng: 77.7200,
      ),
      // Trip 101 - Tirupur Stop
      LRModel(
        lrId: 'lr_6',
        lrNumber: 'LR047/26-27',
        consignorName: 'Classic Printers',
        consignorPhone: '98940 11223',
        consigneeName: 'Standard Stitching',
        consigneePhone: '98940 33445',
        destination: 'Tirupur',
        address: '15, Avinashi Road, Tirupur',
        qty: 15,
        weight: 2.0,
        cooly: 100.0,
        toPay: 9000.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 11.1105,
        receiverLng: 77.3380,
      ),
      
      // Trip 102 - Madurai Stop
      LRModel(
        lrId: 'lr_7',
        lrNumber: 'LR-MDR-01',
        consignorName: 'Virudhunagar Oils',
        consignorPhone: '+91 95000 12345',
        consigneeName: 'Pandian Stores',
        consigneePhone: '+91 95000 54321',
        destination: 'Madurai',
        address: '22, Simmakkal Road, Madurai',
        qty: 100,
        weight: 15.0,
        cooly: 500.0,
        toPay: 32000.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 9.9252,
        receiverLng: 78.1198,
      ),
      // Trip 102 - Trichy Stop
      LRModel(
        lrId: 'lr_8',
        lrNumber: 'LR-TRY-01',
        consignorName: 'Giga Warehousing',
        consignorPhone: '+91 95000 54321',
        consigneeName: 'Trichy Central Traders',
        consigneePhone: '+91 95000 98765',
        destination: 'Trichy',
        address: '7, Cantonment, Trichy',
        qty: 60,
        weight: 7.0,
        cooly: 200.0,
        toPay: 18000.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 10.8050,
        receiverLng: 78.6856,
      ),
      LRModel(
        lrId: 'lr_9',
        lrNumber: 'LR-TRY-02',
        consignorName: 'Alloy Industries',
        consignorPhone: '+91 95000 98765',
        consigneeName: 'St Joseph Iron Mart',
        consigneePhone: '+91 95000 11111',
        destination: 'Trichy',
        address: '109, Palakarai Road, Trichy',
        qty: 90,
        weight: 10.0,
        cooly: 250.0,
        toPay: 29500.0,
        account: 0.0,
        paid: 0.0,
        extraCharges: '',
        chargeAmount: 0.0,
        deliveryStatus: 'pending',
        receiverLat: 10.8080,
        receiverLng: 78.6890,
      ),
    ]);

    _broadcast();
  }

  void _broadcast() {
    _usersController.add(List.unmodifiable(_users));
    _tripsController.add(List.unmodifiable(_trips));
    _lrsController.add(List.unmodifiable(_lrs));
  }

  UserModel? authenticate(String username, String password) {
    try {
      return _users.firstWhere((u) => u.username == username.toLowerCase().trim());
    } catch (_) {
      return null;
    }
  }

  UserModel? getUser(String uid) {
    try {
      return _users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  List<UserModel> getAllUsers() {
    return List.from(_users);
  }

  void updateUserLocation(String uid, double lat, double lng, {double battery = 100.0, String? status}) {
    final idx = _users.indexWhere((u) => u.uid == uid);
    if (idx != -1) {
      final user = _users[idx];
      _users[idx] = user.copyWith(
        lastLocation: {
          'lat': lat,
          'lng': lng,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        battery: battery,
        status: status ?? user.status,
      );
      _broadcast();
    }
  }

  void updateUserStatus(String uid, String status) {
    final idx = _users.indexWhere((u) => u.uid == uid);
    if (idx != -1) {
      final user = _users[idx];
      _users[idx] = user.copyWith(status: status);
      _broadcast();
    }
  }

  List<TripModel> getTripsForDriver(String driverUid) {
    return _trips.where((t) => t.driverUid == driverUid).toList();
  }

  TripModel? getTrip(String tripId) {
    try {
      return _trips.firstWhere((t) => t.tripId == tripId);
    } catch (_) {
      return null;
    }
  }

  void updateTripStatus(String tripId, String status) {
    final idx = _trips.indexWhere((t) => t.tripId == tripId);
    if (idx != -1) {
      _trips[idx] = _trips[idx].copyWith(status: status);
      _broadcast();
    }
  }

  List<LRModel> getLRsForTrip(String tripId) {
    if (tripId == 'trip_101') {
      return _lrs.where((lr) => ['lr_1', 'lr_2', 'lr_3', 'lr_4', 'lr_5', 'lr_6'].contains(lr.lrId)).toList();
    } else if (tripId == 'trip_102') {
      return _lrs.where((lr) => ['lr_7', 'lr_8', 'lr_9'].contains(lr.lrId)).toList();
    }
    return [];
  }

  void deliverLR(String lrId, double lat, double lng) {
    final idx = _lrs.indexWhere((lr) => lr.lrId == lrId);
    if (idx != -1) {
      _lrs[idx] = _lrs[idx].copyWith(
        deliveryStatus: 'delivered',
        deliveredLat: lat,
        deliveredLng: lng,
        deliveredAt: DateTime.now(),
      );
      _broadcast();
    }
  }
}
