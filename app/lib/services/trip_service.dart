import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/bike_data.dart';

class TripService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ns200_trips.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT NOT NULL,
            end_time TEXT,
            distance_km REAL DEFAULT 0,
            avg_speed REAL DEFAULT 0,
            max_speed REAL DEFAULT 0,
            avg_fuel_eco REAL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE trip_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            rpm INTEGER DEFAULT 0,
            speed INTEGER DEFAULT 0,
            gear INTEGER DEFAULT 0,
            fuel_level REAL DEFAULT 0,
            instant_fuel_eco REAL DEFAULT 0,
            engine_temp REAL DEFAULT 0,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<int> startTrip() async {
    final db = await database;
    return await db.insert('trips', {
      'start_time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endTrip(int tripId) async {
    final db = await database;
    final data = await db.query('trip_data',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );

    if (data.isEmpty) {
      await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
      return;
    }

    final speeds = data.map((d) => d['speed'] as int).toList();
    final avgSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a > b ? a : b).toDouble();
    final avgFuel = _calculateAvgFuelEco(data);
    final distance = _estimateDistance(data);

    await db.update('trips', {
      'end_time': DateTime.now().toIso8601String(),
      'distance_km': distance,
      'avg_speed': avgSpeed,
      'max_speed': maxSpeed,
      'avg_fuel_eco': avgFuel,
    }, where: 'id = ?', whereArgs: [tripId]);
  }

  Future<void> recordDataPoint(int tripId, BikeData data) async {
    final db = await database;
    await db.insert('trip_data', {
      'trip_id': tripId,
      'timestamp': data.timestamp.toIso8601String(),
      'rpm': data.rpm,
      'speed': data.speed,
      'gear': data.gear,
      'fuel_level': data.fuelLevel,
      'instant_fuel_eco': data.instantFuelEco,
      'engine_temp': data.engineTemp,
    });
  }

  Future<List<Trip>> getTrips() async {
    final db = await database;
    final trips = await db.query('trips', orderBy: 'id DESC');

    List<Trip> result = [];
    for (var t in trips) {
      final data = await db.query('trip_data',
        where: 'trip_id = ?',
        whereArgs: [t['id']],
        orderBy: 'timestamp ASC',
      );

      result.add(Trip(
        id: t['id'] as int,
        startTime: DateTime.parse(t['start_time'] as String),
        endTime: t['end_time'] != null ? DateTime.parse(t['end_time'] as String) : null,
        distanceKm: (t['distance_km'] as num?)?.toDouble() ?? 0,
        avgSpeed: (t['avg_speed'] as num?)?.toDouble() ?? 0,
        maxSpeed: (t['max_speed'] as num?)?.toDouble() ?? 0,
        avgFuelEco: (t['avg_fuel_eco'] as num?)?.toDouble() ?? 0,
        dataPoints: data.map((d) => BikeData(
          rpm: d['rpm'] as int,
          speed: d['speed'] as int,
          gear: d['gear'] as int,
          fuelLevel: (d['fuel_level'] as num?)?.toDouble() ?? 0,
          instantFuelEco: (d['instant_fuel_eco'] as num?)?.toDouble() ?? 0,
          engineTemp: (d['engine_temp'] as num?)?.toDouble() ?? 0,
          timestamp: DateTime.parse(d['timestamp'] as String),
        )).toList(),
      ));
    }
    return result;
  }

  Future<void> deleteTrip(int tripId) async {
    final db = await database;
    await db.delete('trip_data', where: 'trip_id = ?', whereArgs: [tripId]);
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  double _calculateAvgFuelEco(List<Map<String, dynamic>> data) {
    final vals = data.map((d) => (d['instant_fuel_eco'] as num?)?.toDouble() ?? 0)
        .where((v) => v > 0).toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double _estimateDistance(List<Map<String, dynamic>> data) {
    double total = 0;
    for (int i = 1; i < data.length; i++) {
      final t1 = DateTime.parse(data[i - 1]['timestamp'] as String);
      final t2 = DateTime.parse(data[i]['timestamp'] as String);
      final hours = t2.difference(t1).inMilliseconds / 3600000.0;
      final speed = (data[i - 1]['speed'] as num?)?.toDouble() ?? 0;
      total += speed * hours;
    }
    return total;
  }
}
