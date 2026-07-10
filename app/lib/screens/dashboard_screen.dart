import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';
import '../widgets/rpm_gauge.dart';
import '../widgets/speed_display.dart';
import '../widgets/gear_indicator.dart';
import '../widgets/fuel_info.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildHeader(context, provider),
                  const SizedBox(height: 16),
                  _buildConnectionStatus(provider),
                  const SizedBox(height: 16),
                  _buildRawDataDisplay(provider),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: RpmGauge(rpm: provider.currentData.rpm),
                  ),
                  const SizedBox(height: 16),
                  SpeedDisplay(speed: provider.currentData.speed),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GearIndicator(
                          gear: provider.currentData.gear,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Engine Temp',
                          '${provider.currentData.engineTemp.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FuelInfo(data: provider.currentData),
                  const SizedBox(height: 16),
                  _buildTripControls(context, provider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BikeProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NS 200', style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Performance Dashboard',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        _buildBluetoothIcon(provider),
      ],
    );
  }

  Widget _buildBluetoothIcon(BikeProvider provider) {
    Color color;
    IconData icon;

    switch (provider.connectionStatus) {
      case ConnectionStatus.connected:
        color = const Color(0xFF00E676);
        icon = Icons.bluetooth_connected;
      case ConnectionStatus.connecting:
      case ConnectionStatus.scanning:
        color = Colors.amber;
        icon = Icons.bluetooth_searching;
      case ConnectionStatus.disconnected:
        color = Colors.white38;
        icon = Icons.bluetooth_disabled;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildConnectionStatus(BikeProvider provider) {
    if (provider.connectionStatus == ConnectionStatus.disconnected) {
      return GestureDetector(
        onTap: () => provider.startScan(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1744), Color(0xFFD50000)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_searching, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Tap to Connect Bike',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.connectionStatus == ConnectionStatus.scanning) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 10),
            Text('Scanning for bike...', style: TextStyle(color: Colors.amber)),
          ],
        ),
      );
    }

    if (provider.connectionStatus == ConnectionStatus.connecting) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 10),
            Text('Connecting...', style: TextStyle(color: Colors.amber)),
          ],
        ),
      );
    }

    // Connected
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676), shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Connected to ${provider.bleService.device?.platformName ?? "Bike"}',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            provider.currentData.rawHex.isEmpty
                ? 'Waiting for data…'
                : 'RAW: ${provider.currentData.rawHex}',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF1744), size: 24),
          const SizedBox(height: 8),
          Text(value,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
              fontFamily: 'Digital',
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataDisplay(BikeProvider provider) {
    final data = provider.currentData;
    if (data.rawBytes.isEmpty) return const SizedBox.shrink();
    final hex = data.rawHex;
    final parts = hex.split(' ');
    final lines = <String>[];
    for (int i = 0; i < parts.length; i += 8) {
      lines.add(parts.sublist(i, i + 8 > parts.length ? parts.length : i + 8).join(' '));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEB3B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering, size: 14, color: Color(0xFFFFEB3B)),
              const SizedBox(width: 6),
              const Text('LIVE RAW DATA',
                style: TextStyle(
                  color: Color(0xFFFFEB3B), fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                )),
              const Spacer(),
              Text('${data.rawBytes.length}B',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(line,
              style: const TextStyle(
                fontFamily: 'monospace', fontSize: 13,
                color: Color(0xFFFFEB3B), height: 1.3,
              )),
          )),
        ],
      ),
    );
  }

  Widget _buildTripControls(BuildContext context, BikeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isTripActive ? 'Recording Trip...' : 'Trip Recorder',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.isTripActive
                      ? 'Data points being saved'
                      : 'Start recording your ride',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: provider.connectionStatus == ConnectionStatus.connected
                ? () {
                    if (provider.isTripActive) {
                      provider.stopTrip();
                    } else {
                      provider.startTrip();
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: provider.isTripActive
                    ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                    : const Color(0xFF00E676).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.isTripActive
                      ? const Color(0xFFFF1744).withValues(alpha: 0.5)
                      : const Color(0xFF00E676).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isTripActive ? Icons.stop : Icons.play_arrow,
                    color: provider.isTripActive
                        ? const Color(0xFFFF1744)
                        : const Color(0xFF00E676),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isTripActive ? 'Stop' : 'Record',
                    style: TextStyle(
                      color: provider.isTripActive
                          ? const Color(0xFFFF1744)
                          : const Color(0xFF00E676),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
