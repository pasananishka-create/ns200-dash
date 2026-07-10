import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';
import 'debug_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  _buildScanSection(context, provider),
                  const SizedBox(height: 16),
                  _buildConnectionInfo(provider),
                  const SizedBox(height: 16),
                  _buildDebugButton(context),
                  const SizedBox(height: 16),
                  _buildAboutSection(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanSection(BuildContext context, BikeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bluetooth, color: Color(0xFFFF1744), size: 20),
              SizedBox(width: 8),
              Text(
                'Bluetooth Connection',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.connectionStatus == ConnectionStatus.disconnected) ...[
            _buildActionButton(
              icon: Icons.search,
              label: 'Scan for Bike',
              onTap: () => provider.startScan(),
            ),
            if (provider.scanMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  provider.scanMessage,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
                ),
              ),
            ],
            if (provider.discoveredDevices.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Discovered Devices:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...provider.discoveredDevices.map((device) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.device.platformName.isNotEmpty
                              ? device.device.platformName
                              : 'Unknown Device',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          device.device.remoteId.toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => provider.connectToDevice(device.device),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Connect',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ] else if (provider.connectionStatus == ConnectionStatus.connected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676), shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to ${provider.bleService.device?.platformName ?? "pulsar2698"}',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.link_off,
              label: 'Disconnect',
              color: const Color(0xFFFF1744),
              onTap: () => provider.disconnect(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = const Color(0xFFFF1744),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfo(BikeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Device Name', 'pulsar2698'),
          _buildInfoRow('MAC Address', provider.bleService.device?.remoteId.toString() ?? '--'),
          _buildInfoRow('Status', provider.connectionStatus == ConnectionStatus.connected ? 'Connected' : 'Disconnected'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildDebugButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFEB3B).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEB3B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.developer_mode, color: Color(0xFFFFEB3B), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BLE Debug Console',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Read/write raw characteristics',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('App Version', '1.0.0'),
          _buildInfoRow('Bike Model', 'Bajaj Pulsar NS200'),
          const SizedBox(height: 12),
          Text(
            'Custom dashboard app for Bajaj Pulsar NS200.\n'
            'Connects via Bluetooth LE to display real-time\n'
            'bike telemetry data.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
