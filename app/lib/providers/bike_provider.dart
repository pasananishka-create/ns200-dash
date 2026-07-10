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
  StreamSubscription? _connectionStateSub;
  Timer? _pollTimer;
  String _scanMessage = '';
  final List<RawLogEntry> _rawDataLog = [];

  BikeData get currentData => _currentData;
  ConnectionStatus get connectionStatus => _connectionStatus;
  List<ScanResult> get discoveredDevices => _discoveredDevices;
  Trip? get activeTrip => _activeTrip;
  List<Trip> get trips => _trips;
  bool get isTripActive => _activeTripId != null;
  String get scanMessage => _scanMessage;
  List<RawLogEntry> get rawDataLog => _rawDataLog;

  void _logRawData(BikeData data) {
    _rawDataLog.insert(0, RawLogEntry(data.rawHex, data.rawBytes.length, DateTime.now()));
    if (_rawDataLog.length > 100) {
      _rawDataLog.removeRange(100, _rawDataLog.length);
    }
  }


  BleService get bleService => _bleService;

  Future<void> startScan() async {
    _connectionStatus = ConnectionStatus.scanning;
    _discoveredDevices.clear();
    notifyListeners();

    try {
      // 1. Check Bluetooth is on
      _scanMessage = 'Checking Bluetooth…';
      notifyListeners();
      final btOn = await _bleService.isBluetoothOn();
      if (!btOn) {
        _scanMessage = 'Bluetooth is off. Turn it on and try again.';
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      // 2. Scan for ALL nearby BLE devices (flutter_blue_plus handles permission request)
      _scanMessage = 'Scanning for nearby BLE devices…';
      notifyListeners();
      final results = await _bleService.scanForDevices(timeout: const Duration(seconds: 15));
      _discoveredDevices.addAll(results);

      // 3. If we found our target bike, auto-connect
      final bike = results.cast<ScanResult?>().firstWhere(
        (r) => r != null && BleService.isTargetDevice(r),
        orElse: () => null,
      );

      if (bike != null) {
        _scanMessage = 'Connecting to ${bike.device.platformName}…';
        notifyListeners();
        await connectToDevice(bike.device);
        _scanMessage = '';
      } else {
        if (results.isEmpty) {
          _scanMessage = 'No BLE devices found nearby. Check that Bluetooth is on and try again.';
        } else {
          _scanMessage = 'Found ${results.length} device(s), but none matched "${BleService.targetDeviceName}".'
              ' Tap a device below to connect manually.';
        }
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
      }
    } catch (e) {
      _scanMessage = 'Error: ${e.toString()}';
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
    // Listen to connection state changes (handle unexpected disconnects)
    _connectionStateSub?.cancel();
    _connectionStateSub = _bleService.connectionStateStream.listen((state) {
      if (state == BluetoothConnectionState.disconnected &&
          _connectionStatus == ConnectionStatus.connected) {
        _pollTimer?.cancel();
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
      }
    });

    // Listen to BLE notification stream for real-time data
    _dataSubscription?.cancel();
    _dataSubscription = _bleService.dataStream.listen((data) {
      _currentData = data;
      _logRawData(data);
      notifyListeners();
      if (_activeTripId != null) {
        _tripService.recordDataPoint(_activeTripId!, data);
      }
    });

    // Periodic read polling as fallback (for characteristics without notify)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final data = await _bleService.readBikeData();
      if (data != null) {
        _currentData = data;
        _logRawData(data);
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
    _connectionStateSub?.cancel();
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
    _connectionStateSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}

class RawLogEntry {
  final String hex;
  final int length;
  final DateTime timestamp;
  RawLogEntry(this.hex, this.length, this.timestamp);
}
