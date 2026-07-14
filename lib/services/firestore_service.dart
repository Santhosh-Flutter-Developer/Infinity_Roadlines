import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/lr_model.dart';
import 'mock_database.dart';

abstract class FirestoreService {
  Stream<List<UserModel>> watchAllDrivers();
  Stream<List<TripModel>> watchTripsForDriver(String driverUid);
  Stream<List<LRModel>> watchLRsForTrip(String tripId);
  Future<void> updateDriverLocation(String uid, double lat, double lng, double battery, String status);
  Future<void> updateTripStatus(String tripId, String status);
  Future<void> deliverLR(String lrId, double lat, double lng);
}

class MockFirestoreService implements FirestoreService {
  final MockDatabase _db = MockDatabase();

  @override
  Stream<List<UserModel>> watchAllDrivers() async* {
    yield _db.getAllUsers().where((u) => u.role == 'driver').toList();
    await for (final users in _db.usersStream) {
      yield users.where((u) => u.role == 'driver').toList();
    }
  }

  @override
  Stream<List<TripModel>> watchTripsForDriver(String driverUid) async* {
    yield _db.getTripsForDriver(driverUid);
    await for (final trips in _db.tripsStream) {
      yield trips.where((t) => t.driverUid == driverUid).toList();
    }
  }

  @override
  Stream<List<LRModel>> watchLRsForTrip(String tripId) async* {
    yield _db.getLRsForTrip(tripId);
    await for (final lrs in _db.lrsStream) {
      if (tripId == 'trip_101') {
        yield lrs.where((lr) => ['lr_1', 'lr_2', 'lr_3', 'lr_4', 'lr_5', 'lr_6'].contains(lr.lrId)).toList();
      } else if (tripId == 'trip_102') {
        yield lrs.where((lr) => ['lr_7', 'lr_8', 'lr_9'].contains(lr.lrId)).toList();
      } else {
        yield [];
      }
    }
  }

  @override
  Future<void> updateDriverLocation(String uid, double lat, double lng, double battery, String status) async {
    _db.updateUserLocation(uid, lat, lng, battery: battery, status: status);
  }

  @override
  Future<void> updateTripStatus(String tripId, String status) async {
    _db.updateTripStatus(tripId, status);
  }

  @override
  Future<void> deliverLR(String lrId, double lat, double lng) async {
    _db.deliverLR(lrId, lat, lng);
  }
}
