import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bike_data.dart';

class BleService {
  static const String targetDeviceName = 'pulsar2698';

  BluetoothDevice? _device;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  bool _isScanning = false;
  StreamSubscription? _connectionSubscription;
  final List<_CharListener> _charListeners = [];

  final _dataStreamController = StreamController<BikeData>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  Stream<BikeData> get dataStream => _dataStreamController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  BluetoothConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isScanning => _isScanning;

  BluetoothDevice? get device => _device;

  /// Get the latest discovered services, or null if not connected yet.
  Future<List<BluetoothService>> getServices() async {
    if (_device == null) return [];
    try {
      return await _device!.discoverServices();
    } catch (_) {
      return [];
    }
  }

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

  /// Check if Bluetooth is currently enabled (with timeout).
  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .timeout(const Duration(seconds: 5))
          .first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      // timeout or stream error – BT is off or unavailable
      return false;
    }
  }

  /// Scan for ALL nearby BLE devices, stopping early if [targetDeviceName] is found.
  /// Uses LOW_LATENCY scan mode for best discovery on Android.
  /// Returns the full list of discovered devices (not filtered).
  Future<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 15)}) async {
    _isScanning = true;
    final results = <ScanResult>[];
    final completer = Completer<void>();
    StreamSubscription? sub;
    Timer? timer;

    try {
      await FlutterBluePlus.startScan(androidScanMode: AndroidScanMode.lowLatency);

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
    } catch (e) {
      // scan failed (e.g. permission denied) – return whatever we have
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
    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } catch (_) {
      return;
    }

    // Cancel any previous notification listeners
    for (final cl in _charListeners) {
      await cl.sub?.cancel();
    }
    _charListeners.clear();

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.notify) {
          try {
            await char.setNotifyValue(true);
            final sub = char.onValueReceived.listen((value) {
              final data = _parseBikeData(value);
              if (data != null) {
                _dataStreamController.add(data);
              }
            });
            _charListeners.add(_CharListener(char.uuid.toString(), sub));
          } catch (_) {
            // This characteristic doesn't support notify enable — skip it
          }
        }
      }
    }
  }

  Future<BikeData?> readCharacteristic(String serviceUuid, String charUuid) async {
    if (_device == null || !isConnected) return null;
    try {
      final services = await _device!.discoverServices();
      for (var svc in services) {
        if (svc.uuid.toString() == serviceUuid) {
          for (var char in svc.characteristics) {
            if (char.uuid.toString() == charUuid && char.properties.read) {
              final value = await char.read();
              return BikeData(rawBytes: value, timestamp: DateTime.now());
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<BikeData?> readBikeData() async {
    if (_device == null || !isConnected) return null;

    try {
      List<BluetoothService> services = await _device!.discoverServices();

      // Try all readable characteristics across all services
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.read) {
            try {
              List<int> value = await char.read();
              final data = _parseBikeData(value);
              if (data != null) return data;
            } catch (_) {
              // skip characteristics that fail to read
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

    // TODO: Reverse engineer actual byte encoding.
    // Raw bytes are captured in BikeData.rawBytes so they can be viewed
    // on the debug screen. Use the debug screen to correlate raw byte
    // values with the bike's physical display to decode the protocol.
    return BikeData(
      rawBytes: data,
      timestamp: DateTime.now(),
    );
  }

  Future<void> sendCommand(List<int> command) async {
    if (_device == null || !isConnected) return;

    try {
      List<BluetoothService> services = await _device!.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            try {
              await char.write(command);
              return; // sent on the first writable char
            } catch (_) {
              // try the next writable char
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    for (final cl in _charListeners) {
      await cl.sub?.cancel();
    }
    _charListeners.clear();
    await _device?.disconnect();
    _device = null;
    _connectionState = BluetoothConnectionState.disconnected;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  void dispose() {
    _dataStreamController.close();
    _connectionStateController.close();
    _connectionSubscription?.cancel();
    for (final cl in _charListeners) {
      cl.sub?.cancel();
    }
    _charListeners.clear();
  }
}

class _CharListener {
  final String characteristicUuid;
  final StreamSubscription? sub;
  _CharListener(this.characteristicUuid, this.sub);
}
