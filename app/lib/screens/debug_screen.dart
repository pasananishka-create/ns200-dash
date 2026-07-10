import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/bike_provider.dart';

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
                            color: Colors.white.withValues(alpha: 0.05),
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
                    _buildDiscoverSection(context, provider),
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

  Widget _buildDiscoverSection(BuildContext context, BikeProvider provider) {
    return Expanded(
      child: FutureBuilder<List<BluetoothService>>(
        future: provider.bleService.getServices(),
        builder: (context, snapshot) {
          final services = snapshot.data ?? [];
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Services & Characteristics',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: services.isEmpty
                      ? const Center(child: Text('No services found',
                          style: TextStyle(color: Colors.white38, fontSize: 12)))
                      : ListView(
                          children: services.map((svc) => _buildServiceTile(context, svc)).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, BluetoothService svc) {
    final svcId = svc.uuid.toString();
    final chars = svc.characteristics;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(svcId,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            )),
          const SizedBox(height: 4),
          ...chars.map((char) => _buildCharTile(context, char, svcId)),
        ],
      ),
    );
  }

  Widget _buildCharTile(BuildContext context, BluetoothCharacteristic char, String svcId) {
    final charId = char.uuid.toString();
    final props = <String>[];
    if (char.properties.read) props.add('R');
    if (char.properties.write) props.add('W');
    if (char.properties.notify) props.add('N');

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      child: GestureDetector(
        onTap: char.properties.read
            ? () => _readChar(context, svcId, charId)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(charId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  )),
              ),
              const SizedBox(width: 8),
              Text(props.join('/'),
                style: TextStyle(
                  color: const Color(0xFF00E676),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
              if (char.properties.read) ...[
                const SizedBox(width: 6),
                const Icon(Icons.download, size: 12, color: Colors.white38),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _readChar(BuildContext context, String svcId, String charId) async {
    final provider = context.read<BikeProvider>();
    try {
      final data = await provider.bleService.readCharacteristic(svcId, charId);
      if (data == null || data.rawBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data or characteristic not readable')),
          );
        }
        return;
      }
      final hex = data.rawHex;
      final ascii = data.rawBytes.map((b) => b >= 32 && b <= 126 ? String.fromCharCode(b) : '.').join();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(charId, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text('HEX: $hex',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFFFEB3B))),
                Text('ASCII: $ascii',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildWriteSection(BuildContext context, BikeProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontFamily: 'monospace'),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFEB3B).withValues(alpha: 0.3)),
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
