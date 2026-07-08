import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedDisplay extends StatefulWidget {
  final int speed;

  const SpeedDisplay({super.key, this.speed = 0});

  @override
  State<SpeedDisplay> createState() => _SpeedDisplayState();
}

class _SpeedDisplayState extends State<SpeedDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _smoothSpeed;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _smoothSpeed = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.addListener(() {
      setState(() => _displayValue = _smoothSpeed.value);
    });
  }

  @override
  void didUpdateWidget(SpeedDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _smoothSpeed = Tween<double>(
        begin: _displayValue,
        end: widget.speed.toDouble(),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                _displayValue.toStringAsFixed(0),
                style: const TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'km/h',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMiniStat('MAX', '${widget.speed}', const Color(0xFFFF1744)),
              const SizedBox(height: 6),
              _buildMiniStat('LIMIT', '120', Colors.white38),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 3, height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label,
              style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ],
    );
  }
}
