/// Utility class for weather-related calculations and conversions
class WeatherUtils {
  WeatherUtils._();

  /// Convert Kelvin to Celsius
  static double kelvinToCelsius(double kelvin) => kelvin - 273.15;

  /// Convert Celsius to Fahrenheit
  static double celsiusToFahrenheit(double celsius) => celsius * 9 / 5 + 32;

  /// Convert m/s to km/h
  static double msToKmh(double ms) => ms * 3.6;

  /// Convert m/s to mph
  static double msToMph(double ms) => ms * 2.237;

  /// Calculate heat index (feels like in summer)
  static double heatIndex(double tempC, double humidity) {
    if (tempC < 27) return tempC;
    final t = celsiusToFahrenheit(tempC);
    final r = humidity;

    double hi = -42.379 +
        2.04901523 * t +
        10.14333127 * r -
        0.22475541 * t * r -
        0.00683783 * t * t -
        0.05481717 * r * r +
        0.00122874 * t * t * r +
        0.00085282 * t * r * r -
        0.00000199 * t * t * r * r;

    return (hi - 32) * 5 / 9;
  }

  /// Calculate wind chill (feels like in winter)
  static double windChill(double tempC, double windKmh) {
    if (tempC > 10 || windKmh < 4.8) return tempC;
    return 13.12 +
        0.6215 * tempC -
        11.37 * _pow(windKmh, 0.16) +
        0.3965 * tempC * _pow(windKmh, 0.16);
  }

  static double _pow(double base, double exp) {
    if (base <= 0) return 0;
    return base.toDouble() * (exp == 0.16 ? _sixteenthRoot(base) / base : 1);
  }

  static double _sixteenthRoot(double value) {
    // Approximation using dart:math would be better, using Newton's method
    double result = 1.0;
    for (int i = 0; i < 20; i++) {
      result = result - (result * result * result * result * result * result *
          result * result * result * result * result * result * result *
          result * result * result - value) / (16 * result * result * result *
          result * result * result * result * result * result * result *
          result * result * result * result * result);
    }
    return result;
  }

  /// Calculate feels like temperature
  static double feelsLike(double tempC, double humidity, double windKmh) {
    if (tempC >= 27 && humidity >= 40) {
      return heatIndex(tempC, humidity);
    } else if (tempC <= 10 && windKmh >= 4.8) {
      return windChill(tempC, windKmh);
    }
    return tempC;
  }

  /// Estimate sunburn time in minutes based on UV index and skin type
  static int estimateSunburnTime(double uvIndex, {int skinType = 3}) {
    if (uvIndex <= 0) return 999;
    // Skin type multipliers (1=very fair, 6=very dark)
    final multipliers = {1: 2.5, 2: 3.0, 3: 4.0, 4: 5.0, 5: 8.0, 6: 15.0};
    final multiplier = multipliers[skinType] ?? 4.0;
    return (200 * multiplier / (3 * uvIndex)).round();
  }

  /// Get UV level description
  static String getUvDescription(double uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  /// Get wind direction from degrees
  static String getWindDirection(double degrees) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Get Beaufort scale description
  static String getWindDescription(double speedKmh) {
    if (speedKmh < 2) return 'Calm';
    if (speedKmh < 12) return 'Light breeze';
    if (speedKmh < 20) return 'Gentle breeze';
    if (speedKmh < 29) return 'Moderate breeze';
    if (speedKmh < 39) return 'Fresh breeze';
    if (speedKmh < 50) return 'Strong breeze';
    if (speedKmh < 62) return 'High wind';
    if (speedKmh < 75) return 'Gale';
    if (speedKmh < 89) return 'Strong gale';
    if (speedKmh < 103) return 'Storm';
    if (speedKmh < 118) return 'Violent storm';
    return 'Hurricane force';
  }

  /// Get weather condition icon mapping (OpenWeatherMap code to icon)
  static String getWeatherEmoji(int conditionCode) {
    if (conditionCode >= 200 && conditionCode < 300) return '⛈️';
    if (conditionCode >= 300 && conditionCode < 400) return '🌦️';
    if (conditionCode >= 500 && conditionCode < 600) return '🌧️';
    if (conditionCode >= 600 && conditionCode < 700) return '❄️';
    if (conditionCode >= 700 && conditionCode < 800) return '🌫️';
    if (conditionCode == 800) return '☀️';
    if (conditionCode == 801) return '🌤️';
    if (conditionCode == 802) return '⛅';
    if (conditionCode >= 803) return '☁️';
    return '🌡️';
  }
}
