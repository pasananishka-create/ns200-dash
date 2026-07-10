import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bike_data.dart';
import '../services/ble_service.dart';
import '../services/trip_service.dart';

enum ConnectionStatus { disconnected, scanning, connecting, connected }

class BikeProvider extends ChangeNotifier {
  final BleService _bleService = BleService();
  final TripService _tripService = TripService();
  final List<ScanResult> _discoveredDevices = [];

  BikeData _currentData = BikeData();
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Trip? _activeTrip;
  List<Trip> _trips = [];
  int? _activeTripId;
  StreamSubscription? _dataSubscription;
  Timer? _pollTimer;

  BikeData get currentData => _currentData;
  ConnectionStatus get connectionStatus => _connectionStatus;
  List<ScanResult> get discoveredDevices => _discoveredDevices;
  Trip? get activeTrip => _activeTrip;
  List<Trip> get trips => _trips;
  bool get isTripActive => _activeTripId != null;

  BleService get bleService => _bleService;

  Future<void> startScan() async {
    _connectionStatus = ConnectionStatus.scanning;
    _discoveredDevices.clear();
    notifyListeners();

    try {
      // 1. Check Bluetooth is on
      final btOn = await _bleService.isBluetoothOn();
      if (!btOn) {
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      // 2. Scan for ALL nearby BLE devices (flutter_blue_plus handles permission request)
      final results = await _bleService.scanForDevices(timeout: const Duration(seconds: 15));
      _discoveredDevices.addAll(results);

      // 3. If we found our target bike, auto-connect
      final bike = results.cast<ScanResult?>().firstWhere(
        (r) => r != null && BleService.isTargetDevice(r),
        orElse: () => null,
      );

      if (bike != null) {
        await connectToDevice(bike.device);
      } else {
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
      }
    } catch (e) {
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    final success = await _bleService.connectToBike(device);
    if (success) {
      _connectionStatus = ConnectionStatus.connected;
      _startDataPolling();
    } else {
      _connectionStatus = ConnectionStatus.disconnected;
    }
    notifyListeners();
    return success;
  }

  void _startDataPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final data = await _bleService.readBikeData();
      if (data != null) {
        _currentData = data;
        notifyListeners();
        if (_activeTripId != null) {
          await _tripService.recordDataPoint(_activeTripId!, data);
        }
      }
    });
  }

  Future<void> startTrip() async {
    if (_activeTripId != null) return;
    final id = await _tripService.startTrip();
    _activeTripId = id;
    _activeTrip = Trip(startTime: DateTime.now());
    notifyListeners();
  }

  Future<void> stopTrip() async {
    if (_activeTripId == null) return;
    await _tripService.endTrip(_activeTripId!);
    _activeTripId = null;
    _activeTrip = null;
    await loadTrips();
    notifyListeners();
  }

  Future<void> loadTrips() async {
    _trips = await _tripService.getTrips();
    notifyListeners();
  }

  Future<void> deleteTrip(int tripId) async {
    await _tripService.deleteTrip(tripId);
    await loadTrips();
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    if (_activeTripId != null) {
      await stopTrip();
    }
    await _bleService.disconnect();
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _dataSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
