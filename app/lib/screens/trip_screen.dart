import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/bike_provider.dart';
import '../models/bike_data.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BikeProvider>().loadTrips();
    });
  }

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
                  Text('Trips', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.trips.length} trips recorded',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (provider.trips.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route, size: 64, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'No trips yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect to your bike and start recording',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.trips.length,
                        itemBuilder: (context, index) {
                          final trip = provider.trips[index];
                          return _buildTripCard(context, trip, provider);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip, BikeProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final speedColor = Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(trip.startTime),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (trip.endTime != null)
                      Text(
                        _formatDuration(trip.duration),
                        style: const TextStyle(
                          color: Color(0xFFFF1744),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat('Distance', '${trip.distanceKm.toStringAsFixed(1)} km', speedColor),
                    const SizedBox(width: 16),
                    _buildStat('Avg Speed', '${trip.avgSpeed.toStringAsFixed(0)} km/h', speedColor),
                    const SizedBox(width: 16),
                    _buildStat('Max Speed', '${trip.maxSpeed.toStringAsFixed(0)} km/h', const Color(0xFFFF1744)),
                  ],
                ),
                if (trip.avgFuelEco > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStat('Avg Fuel', '${trip.avgFuelEco.toStringAsFixed(1)} km/l', Colors.white70),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trip.dataPoints.isNotEmpty)
            SizedBox(
              height: 120,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _buildSpeedChart(trip.dataPoints),
              ),
            ),
          if (trip.id != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _confirmDelete(context, trip.id!, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 14, color: Color(0xFFFF1744)),
                          SizedBox(width: 4),
                          Text('Delete', style: TextStyle(color: Color(0xFFFF1744), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChart(List<BikeData> data) {
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.speed.toDouble())
    ).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFF1744),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF1744).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int tripId, BikeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Trip', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this trip?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTrip(tripId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF1744))),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${d.inSeconds.remainder(60)}s';
  }
}
