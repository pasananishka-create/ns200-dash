import 'package:flutter/material.dart';
import '../models/bike_data.dart';

class FuelInfo extends StatelessWidget {
  final BikeData data;

  const FuelInfo({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_gas_station, color: const Color(0xFFFF1744), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Fuel Economy',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFuelStat(
                  'Instant',
                  '${data.instantFuelEco.toStringAsFixed(1)}',
                  'km/l',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
              Expanded(
                child: _buildFuelStat(
                  'Average',
                  '${data.avgFuelEco.toStringAsFixed(1)}',
                  'km/l',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
              Expanded(
                child: _buildFuelStat(
                  'Range',
                  '${data.distanceToEmpty}',
                  'km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFuelBar(data.fuelLevel),
        ],
      ),
    );
  }

  Widget _buildFuelStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(value,
          style: const TextStyle(
            fontFamily: 'Digital',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text('$label ($unit)',
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
        ),
      ],
    );
  }

  Widget _buildFuelBar(double level) {
    final clampedLevel = level.clamp(0, 1);
    final segments = 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(segments, (i) {
            final filled = i / segments < clampedLevel;
            final fillColor = clampedLevel < 0.2
                ? const Color(0xFFFF1744)
                : clampedLevel < 0.5
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFF00E676);

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 6,
                decoration: BoxDecoration(
                  color: filled ? fillColor.withOpacity(0.8) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('E', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
            Text('F', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
