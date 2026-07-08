class BikeData {
  final int rpm;
  final int speed;
  final int gear;
  final double fuelLevel;
  final double instantFuelEco;
  final double avgFuelEco;
  final int distanceToEmpty;
  final double engineTemp;
  final int voltage;
  final DateTime timestamp;

  BikeData({
    this.rpm = 0,
    this.speed = 0,
    this.gear = 0,
    this.fuelLevel = 0,
    this.instantFuelEco = 0,
    this.avgFuelEco = 0,
    this.distanceToEmpty = 0,
    this.engineTemp = 0,
    this.voltage = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  BikeData copyWith({
    int? rpm,
    int? speed,
    int? gear,
    double? fuelLevel,
    double? instantFuelEco,
    double? avgFuelEco,
    int? distanceToEmpty,
    double? engineTemp,
    int? voltage,
  }) {
    return BikeData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      gear: gear ?? this.gear,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      instantFuelEco: instantFuelEco ?? this.instantFuelEco,
      avgFuelEco: avgFuelEco ?? this.avgFuelEco,
      distanceToEmpty: distanceToEmpty ?? this.distanceToEmpty,
      engineTemp: engineTemp ?? this.engineTemp,
      voltage: voltage ?? this.voltage,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rpm': rpm,
    'speed': speed,
    'gear': gear,
    'fuelLevel': fuelLevel,
    'instantFuelEco': instantFuelEco,
    'avgFuelEco': avgFuelEco,
    'distanceToEmpty': distanceToEmpty,
    'engineTemp': engineTemp,
    'voltage': voltage,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BikeData.fromJson(Map<String, dynamic> json) => BikeData(
    rpm: json['rpm'] ?? 0,
    speed: json['speed'] ?? 0,
    gear: json['gear'] ?? 0,
    fuelLevel: (json['fuelLevel'] ?? 0).toDouble(),
    instantFuelEco: (json['instantFuelEco'] ?? 0).toDouble(),
    avgFuelEco: (json['avgFuelEco'] ?? 0).toDouble(),
    distanceToEmpty: json['distanceToEmpty'] ?? 0,
    engineTemp: (json['engineTemp'] ?? 0).toDouble(),
    voltage: json['voltage'] ?? 0,
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class Trip {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double avgSpeed;
  final double maxSpeed;
  final double avgFuelEco;
  final List<BikeData> dataPoints;

  Trip({
    this.id,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0,
    this.avgSpeed = 0,
    this.maxSpeed = 0,
    this.avgFuelEco = 0,
    this.dataPoints = const [],
  });

  Duration get duration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'distanceKm': distanceKm,
    'avgSpeed': avgSpeed,
    'maxSpeed': maxSpeed,
    'avgFuelEco': avgFuelEco,
    'dataPoints': dataPoints.map((d) => d.toJson()).toList(),
  };
}
