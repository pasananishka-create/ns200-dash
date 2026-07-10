import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';
import '../services/ble_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('BLE Debug', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (provider.connectionStatus != ConnectionStatus.connected)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.bluetooth_disabled, size: 48, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('Connect to bike first',
                              style: TextStyle(color: Colors.white38, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildSection(context, 'Service UUIDs', [
                      '0020676e-6972-6565-6e69-676e4543544f (Engineering Ctrl)',
                      '0010676e-6972-6565-6e69-676e4543544f (Engineering Cfg)',
                      'f000ffd0-0451-4000-b000-000000000000 (TI Sensor)',
                    ]),
                    const SizedBox(height: 16),
                    _buildReadSection(context, provider),
                    const SizedBox(height: 16),
                    _buildWriteSection(context, provider),
                    const SizedBox(height: 16),
                    _buildDataLog(provider),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(item,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReadSection(BuildContext context, BikeProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Read Characteristics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          _buildReadButton(context, '1120676e...  (Eng Ctrl)', '1120676e-6972-6565-6e69-676e4543544f', BleService.serviceEngineeringCtrl, BleService.charCtrlRead),
          const SizedBox(height: 8),
          _buildReadButton(context, '0a10676e...  (Eng Cfg)', '0a10676e-6972-6565-6e69-676e4543544f', BleService.serviceEngineeringCfg, BleService.charCfgRead),
          const SizedBox(height: 8),
          _buildReadButton(context, 'f000ffd1...  (TI Sensor)', 'f000ffd1-0451-4000-b000-000000000000', BleService.serviceTiSensor, BleService.charTiData),
        ],
      ),
    );
  }

  Widget _buildReadButton(BuildContext context, String label, String charUuid, String serviceUuid, String characteristicUuid) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: () async {
            try {
              final device = provider.bleService.device;
              if (device == null) return;

              final services = await device.discoverServices();
              for (var svc in services) {
                if (svc.uuid.toString() == serviceUuid) {
                  for (var char in svc.characteristics) {
                    if (char.uuid.toString() == characteristicUuid && char.properties.read) {
                      final value = await char.read();
                      final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
                      final ascii = value.map((b) => b >= 32 && b <= 126 ? String.fromCharCode(b) : '.').join();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1A1A1A),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text('HEX: $hex',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFFFEB3B))),
                                Text('ASCII: $ascii',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white38)),
                              ],
                            ),
                            duration: const Duration(seconds: 8),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                      return;
                    }
                  }
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.download, size: 16, color: Color(0xFFFF1744)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFFFF1744)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWriteSection(BuildContext context, BikeProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write Test Command',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          _buildHexInput(context, provider),
        ],
      ),
    );
  }

  Widget _buildHexInput(BuildContext context, BikeProvider provider) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. 01 02 FF',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontFamily: 'monospace'),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F\s]')),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final hexStr = controller.text.trim();
            if (hexStr.isEmpty) return;
            try {
              final bytes = hexStr.split(RegExp(r'\s+')).map((s) => int.parse(s, radix: 16)).toList();
              await provider.bleService.sendCommand(bytes);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Command sent', style: TextStyle(color: Color(0xFF00E676))),
                    backgroundColor: Color(0xFF1A1A1A),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid hex: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFD50000)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDataLog(BikeProvider provider) {
    final data = provider.currentData;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Raw BLE Data',
            style: TextStyle(color: Color(0xFFFFEB3B), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFEB3B).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.rawHex.isEmpty ? '(awaiting data)' : data.rawHex,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFEB3B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.rawBytes.length} bytes',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Decoded Fields (protocol unknown)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          _buildDataRow('RPM', '${data.rpm}'),
          _buildDataRow('Speed', '${data.speed} km/h'),
          _buildDataRow('Gear', '${data.gear}'),
          _buildDataRow('Fuel Level', '${(data.fuelLevel * 100).toStringAsFixed(0)}%'),
          _buildDataRow('Engine Temp', '${data.engineTemp.toStringAsFixed(1)}°C'),
          _buildDataRow('Instant FE', '${data.instantFuelEco.toStringAsFixed(1)} km/l'),
          _buildDataRow('Distance to Empty', '${data.distanceToEmpty} km'),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
