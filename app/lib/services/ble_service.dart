import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bike_data.dart';

class BleService {
  static const String targetDeviceName = 'pulsar2698';

  // Custom service UUIDs from RE
  static const String serviceEngineeringCtrl = '0020676e-6972-6565-6e69-676e4543544f';
  static const String serviceEngineeringCfg = '0010676e-6972-6565-6e69-676e4543544f';
  static const String serviceTiSensor = 'f000ffd0-0451-4000-b000-000000000000';

  // Characteristic UUIDs
  static const String charCtrlRead = '1120676e-6972-6565-6e69-676e4543544f';
  static const String charCtrlWrite = '1020676e-6972-6565-6e69-676e4543544f';
  static const String charCfgRead = '0a10676e-6972-6565-6e69-676e4543544f';
  static const String charTiData = 'f000ffd1-0451-4000-b000-000000000000';

  BluetoothDevice? _device;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  bool _isScanning = false;
  StreamSubscription? _connectionSubscription;

  final _dataStreamController = StreamController<BikeData>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  Stream<BikeData> get dataStream => _dataStreamController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  BluetoothConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isScanning => _isScanning;

  BluetoothDevice? get device => _device;

  /// Check if a scan result matches our target bike name/pattern
  static bool isTargetDevice(ScanResult r) {
    if (r.device.platformName.isNotEmpty &&
        r.device.platformName.toLowerCase() == targetDeviceName) {
      return true;
    }
    if (r.advertisementData.advName.isNotEmpty &&
        r.advertisementData.advName.toLowerCase().contains('pulsar')) {
      return true;
    }
    return false;
  }

  /// Check if Bluetooth is currently enabled.
  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Scan for ALL nearby BLE devices, stopping early if [targetDeviceName] is found.
  /// Returns the full list of discovered devices (not filtered).
  Future<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 15)}) async {
    _isScanning = true;
    final results = <ScanResult>[];
    final completer = Completer<void>();
    StreamSubscription? sub;
    Timer? timer;

    try {
      await FlutterBluePlus.startScan();

      sub = FlutterBluePlus.scanResults.listen((list) {
        for (final r in list) {
          final id = r.device.remoteId;
          if (!results.any((existing) => existing.device.remoteId == id)) {
            results.add(r);
          }
        }
        // Early stop as soon as we spot our target bike
        if (results.any(isTargetDevice)) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
    } finally {
      timer?.cancel();
      await sub?.cancel();
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    }

    return results;
  }

  Future<bool> connectToBike(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect(timeout: const Duration(seconds: 30));

      _connectionSubscription = device.connectionState.listen((state) {
        _connectionState = state;
        _connectionStateController.add(state);
      });

      await _setupNotifications(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _setupNotifications(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              final data = _parseBikeData(value);
              if (data != null) {
                _dataStreamController.add(data);
              }
            });
          }
        }
      }
    } catch (e) {
      // Notification setup failed - data parsing will still work via reads
    }
  }

  Future<BikeData?> readBikeData() async {
    if (_device == null || !isConnected) return null;

    try {
      List<BluetoothService> services = await _device!.discoverServices();

      for (var service in services) {
        if (service.uuid.toString() == serviceTiSensor) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == charTiData && char.properties.read) {
              List<int> value = await char.read();
              return _parseBikeData(value);
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  BikeData? _parseBikeData(List<int> data) {
    if (data.isEmpty) return null;

    try {
      // TODO: Reverse engineer actual byte encoding
      // For now, parse raw bytes as best-effort
      // This will be updated once we decode the protocol
      return BikeData(
        rpm: data.length > 1 ? (data[0] << 8) | data[1] : 0,
        speed: data.length > 2 ? data[2] : 0,
        gear: data.length > 3 ? data[3] : 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> sendCommand(List<int> command) async {
    if (_device == null || !isConnected) return;

    try {
      List<BluetoothService> services = await _device!.discoverServices();

      for (var service in services) {
        if (service.uuid.toString() == serviceEngineeringCtrl) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == charCtrlWrite && char.properties.write) {
              await char.write(command);
              return;
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    await _device?.disconnect();
    _device = null;
    _connectionState = BluetoothConnectionState.disconnected;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  void dispose() {
    _dataStreamController.close();
    _connectionStateController.close();
    _connectionSubscription?.cancel();
  }
}
