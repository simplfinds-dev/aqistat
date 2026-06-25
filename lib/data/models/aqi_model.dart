/// Air Quality Index data model
class AqiData {
  final int aqi;
  final String stationName;
  final DateTime timestamp;
  final double lat;
  final double lon;
  final String dominantPollutant;
  final AqiPollutants? pollutants;
  final AqiForecast? forecast;

  AqiData({
    required this.aqi,
    required this.stationName,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.dominantPollutant,
    this.pollutants,
    this.forecast,
  });

  factory AqiData.fromWaqiJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final city = data['city'] as Map<String, dynamic>;
    final geo = city['geo'] as List;
    final iaqi = data['iaqi'] as Map<String, dynamic>?;
    final time = data['time'] as Map<String, dynamic>;

    return AqiData(
      aqi: (data['aqi'] is int) ? data['aqi'] : int.tryParse(data['aqi'].toString()) ?? 0,
      stationName: city['name'] as String? ?? 'Unknown',
      timestamp: DateTime.tryParse(time['iso'] as String? ?? '') ?? DateTime.now(),
      lat: (geo[0] as num).toDouble(),
      lon: (geo[1] as num).toDouble(),
      dominantPollutant: data['dominentpol'] as String? ?? 'pm25',
      pollutants: iaqi != null ? AqiPollutants.fromJson(iaqi) : null,
      forecast: data['forecast'] != null
          ? AqiForecast.fromJson(data['forecast'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Individual pollutant readings
class AqiPollutants {
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? so2;
  final double? co;

  AqiPollutants({
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
  });

  factory AqiPollutants.fromJson(Map<String, dynamic> json) {
    return AqiPollutants(
      pm25: (json['pm25']?['v'] as num?)?.toDouble(),
      pm10: (json['pm10']?['v'] as num?)?.toDouble(),
      o3: (json['o3']?['v'] as num?)?.toDouble(),
      no2: (json['no2']?['v'] as num?)?.toDouble(),
      so2: (json['so2']?['v'] as num?)?.toDouble(),
      co: (json['co']?['v'] as num?)?.toDouble(),
    );
  }
}

/// AQI forecast data
class AqiForecast {
  final List<AqiDailyForecast> pm25;
  final List<AqiDailyForecast> pm10;
  final List<AqiDailyForecast> o3;

  AqiForecast({
    required this.pm25,
    required this.pm10,
    required this.o3,
  });

  factory AqiForecast.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>?;
    return AqiForecast(
      pm25: _parseForecastList(daily?['pm25']),
      pm10: _parseForecastList(daily?['pm10']),
      o3: _parseForecastList(daily?['o3']),
    );
  }

  static List<AqiDailyForecast> _parseForecastList(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map((e) => AqiDailyForecast.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Daily AQI forecast entry
class AqiDailyForecast {
  final DateTime date;
  final int avg;
  final int min;
  final int max;

  AqiDailyForecast({
    required this.date,
    required this.avg,
    required this.min,
    required this.max,
  });

  factory AqiDailyForecast.fromJson(Map<String, dynamic> json) {
    return AqiDailyForecast(
      date: DateTime.tryParse(json['day'] as String? ?? '') ?? DateTime.now(),
      avg: json['avg'] as int? ?? 0,
      min: json['min'] as int? ?? 0,
      max: json['max'] as int? ?? 0,
    );
  }
}

/// AQI history entry for the 7-day chart
class AqiHistoryEntry {
  final DateTime date;
  final int aqiValue;

  AqiHistoryEntry({required this.date, required this.aqiValue});
}
