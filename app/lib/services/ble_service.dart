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

  List<BluetoothService>? _cachedServices;
  final List<_WorkingChar> _workingReadableChars = [];

  final _dataStreamController = StreamController<BikeData>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  Stream<BikeData> get dataStream => _dataStreamController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  BluetoothConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isScanning => _isScanning;

  BluetoothDevice? get device => _device;

  Future<List<BluetoothService>> getServices() async {
    if (_cachedServices != null) return _cachedServices!;
    if (_device == null) return [];
    try {
      _cachedServices = await _device!.discoverServices();
      return _cachedServices!;
    } catch (_) {
      return [];
    }
  }

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

  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .timeout(const Duration(seconds: 5))
          .first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

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
        if (results.any(isTargetDevice)) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
    } catch (_) {
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
        if (state == BluetoothConnectionState.disconnected) {
          _cachedServices = null;
          _workingReadableChars.clear();
        }
      });

      await getServices();
      await _setupNotifications();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _setupNotifications() async {
    final services = await getServices();
    if (services.isEmpty) return;

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
          }
        }
      }
    }
  }

  Future<BikeData?> readCharacteristic(String serviceUuid, String charUuid) async {
    if (_device == null || !isConnected) return null;
    try {
      final services = await getServices();
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

  /// Read all characteristics known to return data. On first call,
  /// probes every readable characteristic and caches the working ones.
  Future<List<BikeData>> readAllBikeData() async {
    final results = <BikeData>[];
    if (_device == null || !isConnected) return results;

    try {
      final services = await getServices();

      // If we already know which chars work, just read those
      if (_workingReadableChars.isNotEmpty) {
        for (final wc in _workingReadableChars) {
          try {
            final svc = services.firstWhere((s) => s.uuid.toString() == wc.svcUuid);
            final char = svc.characteristics.firstWhere((c) => c.uuid.toString() == wc.charUuid);
            final value = await char.read();
            results.add(BikeData(rawBytes: value, timestamp: DateTime.now()));
          } catch (_) {
          }
        }
        return results;
      }

      // First time: probe all readable characteristics
      for (var svc in services) {
        final svcId = svc.uuid.toString();
        for (var char in svc.characteristics) {
          if (!char.properties.read) continue;
          try {
            final value = await char.read();
            if (value.isNotEmpty) {
              _workingReadableChars.add(_WorkingChar(svcId, char.uuid.toString()));
              results.add(BikeData(rawBytes: value, timestamp: DateTime.now()));
            }
          } catch (_) {
          }
        }
      }
    } catch (_) {
    }
    return results;
  }

  /// Read ALL readable characteristics (no caching).
  Future<List<({String svc, String char, List<int> data})>> readAllCharacteristics() async {
    final out = <({String svc, String char, List<int> data})>[];
    if (_device == null || !isConnected) return out;

    try {
      final services = await getServices();
      for (var svc in services) {
        final svcId = svc.uuid.toString();
        for (var char in svc.characteristics) {
          if (char.properties.read) {
            try {
              final value = await char.read();
              out.add((svc: svcId, char: char.uuid.toString(), data: value));
            } catch (_) {
            }
          }
        }
      }
    } catch (_) {
    }
    return out;
  }

  BikeData? _parseBikeData(List<int> data) {
    if (data.isEmpty) return null;
    return BikeData(rawBytes: data, timestamp: DateTime.now());
  }

  Future<void> sendCommand(List<int> command) async {
    if (_device == null || !isConnected) return;

    try {
      final services = await getServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            try {
              await char.write(command);
              return;
            } catch (_) {
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
    _cachedServices = null;
    _workingReadableChars.clear();
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

class _WorkingChar {
  final String svcUuid;
  final String charUuid;
  _WorkingChar(this.svcUuid, this.charUuid);
}
