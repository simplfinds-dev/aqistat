/// Current weather data model
class WeatherData {
  final double tempCelsius;
  final double feelsLikeCelsius;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double pressure;
  final double windSpeed; // m/s
  final double windDeg;
  final double? windGust;
  final String condition;
  final String conditionDescription;
  final int conditionCode;
  final String icon;
  final int clouds;
  final double? rain1h;
  final double? snow1h;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime timestamp;
  final String cityName;
  final String countryCode;
  final double lat;
  final double lon;

  WeatherData({
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDeg,
    this.windGust,
    required this.condition,
    required this.conditionDescription,
    required this.conditionCode,
    required this.icon,
    required this.clouds,
    this.rain1h,
    this.snow1h,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
    required this.cityName,
    required this.countryCode,
    required this.lat,
    required this.lon,
  });

  factory WeatherData.fromOpenWeatherJson(Map<String, dynamic> json) {
    final weather = json['weather'][0] as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>;
    final coord = json['coord'] as Map<String, dynamic>;

    return WeatherData(
      tempCelsius: (main['temp'] as num).toDouble() - 273.15,
      feelsLikeCelsius: (main['feels_like'] as num).toDouble() - 273.15,
      tempMin: (main['temp_min'] as num).toDouble() - 273.15,
      tempMax: (main['temp_max'] as num).toDouble() - 273.15,
      humidity: main['humidity'] as int,
      pressure: (main['pressure'] as num).toDouble(),
      windSpeed: (wind['speed'] as num).toDouble(),
      windDeg: (wind['deg'] as num?)?.toDouble() ?? 0.0,
      windGust: (wind['gust'] as num?)?.toDouble(),
      condition: weather['main'] as String,
      conditionDescription: weather['description'] as String,
      conditionCode: weather['id'] as int,
      icon: weather['icon'] as String,
      clouds: (json['clouds']?['all'] as int?) ?? 0,
      rain1h: (json['rain']?['1h'] as num?)?.toDouble(),
      snow1h: (json['snow']?['1h'] as num?)?.toDouble(),
      visibility: (json['visibility'] as int?) ?? 10000,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunset'] as int) * 1000),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as int) * 1000),
      cityName: json['name'] as String? ?? '',
      countryCode: sys['country'] as String? ?? '',
      lat: (coord['lat'] as num).toDouble(),
      lon: (coord['lon'] as num).toDouble(),
    );
  }

  double get windSpeedKmh => windSpeed * 3.6;
  bool get isDay => DateTime.now().isAfter(sunrise) && DateTime.now().isBefore(sunset);
}

/// Hourly forecast data
class HourlyForecast {
  final DateTime dateTime;
  final double tempCelsius;
  final double feelsLikeCelsius;
  final int humidity;
  final double windSpeed;
  final double windDeg;
  final String condition;
  final String conditionDescription;
  final int conditionCode;
  final String icon;
  final double rainProbability;
  final double? rainVolume;
  final double? snowVolume;
  final int clouds;
  final double uvIndex;
  final int visibility;

  HourlyForecast({
    required this.dateTime,
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.condition,
    required this.conditionDescription,
    required this.conditionCode,
    required this.icon,
    required this.rainProbability,
    this.rainVolume,
    this.snowVolume,
    required this.clouds,
    required this.uvIndex,
    required this.visibility,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0] as Map<String, dynamic>;
    return HourlyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      tempCelsius: (json['temp'] as num).toDouble() - 273.15,
      feelsLikeCelsius: (json['feels_like'] as num).toDouble() - 273.15,
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: (json['wind_deg'] as num).toDouble(),
      condition: weather['main'] as String,
      conditionDescription: weather['description'] as String,
      conditionCode: weather['id'] as int,
      icon: weather['icon'] as String,
      rainProbability: (json['pop'] as num?)?.toDouble() ?? 0.0,
      rainVolume: (json['rain']?['1h'] as num?)?.toDouble(),
      snowVolume: (json['snow']?['1h'] as num?)?.toDouble(),
      clouds: json['clouds'] as int? ?? 0,
      uvIndex: (json['uvi'] as num?)?.toDouble() ?? 0.0,
      visibility: json['visibility'] as int? ?? 10000,
    );
  }

  double get windSpeedKmh => windSpeed * 3.6;
}

/// Daily forecast data
class DailyForecast {
  final DateTime dateTime;
  final double tempDay;
  final double tempNight;
  final double tempMin;
  final double tempMax;
  final double feelsLikeDay;
  final double feelsLikeNight;
  final int humidity;
  final double windSpeed;
  final double windDeg;
  final String condition;
  final String conditionDescription;
  final int conditionCode;
  final String icon;
  final double rainProbability;
  final double? rainVolume;
  final double? snowVolume;
  final int clouds;
  final double uvIndex;
  final DateTime sunrise;
  final DateTime sunset;
  final String? summary;

  DailyForecast({
    required this.dateTime,
    required this.tempDay,
    required this.tempNight,
    required this.tempMin,
    required this.tempMax,
    required this.feelsLikeDay,
    required this.feelsLikeNight,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.condition,
    required this.conditionDescription,
    required this.conditionCode,
    required this.icon,
    required this.rainProbability,
    this.rainVolume,
    this.snowVolume,
    required this.clouds,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    this.summary,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0] as Map<String, dynamic>;
    final temp = json['temp'] as Map<String, dynamic>;
    final feelsLike = json['feels_like'] as Map<String, dynamic>;

    return DailyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      tempDay: (temp['day'] as num).toDouble() - 273.15,
      tempNight: (temp['night'] as num).toDouble() - 273.15,
      tempMin: (temp['min'] as num).toDouble() - 273.15,
      tempMax: (temp['max'] as num).toDouble() - 273.15,
      feelsLikeDay: (feelsLike['day'] as num).toDouble() - 273.15,
      feelsLikeNight: (feelsLike['night'] as num).toDouble() - 273.15,
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: (json['wind_deg'] as num).toDouble(),
      condition: weather['main'] as String,
      conditionDescription: weather['description'] as String,
      conditionCode: weather['id'] as int,
      icon: weather['icon'] as String,
      rainProbability: (json['pop'] as num?)?.toDouble() ?? 0.0,
      rainVolume: (json['rain'] as num?)?.toDouble(),
      snowVolume: (json['snow'] as num?)?.toDouble(),
      clouds: json['clouds'] as int? ?? 0,
      uvIndex: (json['uvi'] as num?)?.toDouble() ?? 0.0,
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sunset'] as int) * 1000),
      summary: json['summary'] as String?,
    );
  }
}
