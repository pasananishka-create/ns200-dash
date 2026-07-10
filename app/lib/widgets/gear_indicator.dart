import 'package:flutter/material.dart';

class GearIndicator extends StatelessWidget {
  final int gear;

  const GearIndicator({super.key, this.gear = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              gear == 0 ? 'N' : '$gear',
              key: ValueKey(gear),
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: gear == 0 ? const Color(0xFFFFEB3B) : Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'GEAR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final isActive = gear == i + 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFFFF1744) : Colors.white.withValues(alpha: 0.1),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
