
class WeatherHelpers {
  WeatherHelpers._();
  static String getWeatherEmoji(int code) {
    if (code >= 200 && code < 300) return '⛈️';
    if (code >= 300 && code < 400) return '🌦️';
    if (code >= 500 && code < 600) return '🌧️';
    if (code >= 600 && code < 700) return '❄️';
    if (code >= 700 && code < 800) return '🌫️';
    if (code == 800) return '☀️';
    if (code == 801) return '🌤️';
    if (code == 802) return '⛅';
    return '☁️';
  }
  static String pollutantName(String key) {
    switch (key) {
      case 'pm25':
        return 'PM2.5';
      case 'pm10':
        return 'PM10';
      case 'o3':
        return 'Ozone (O₃)';
      case 'no2':
        return 'Nitrogen Dioxide';
      case 'so2':
        return 'Sulfur Dioxide';
      case 'co':
        return 'Carbon Monoxide';
      default:
        return key.toUpperCase();
    }
  }

  static String getAqiLevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }
  static String getOutfitSuggestion(double temp, double rainProb, double uv) {
    final items = <String>[];
    if (temp < 5) items.add('🧥 Heavy coat & layers');
    else if (temp < 15) items.add('🧥 Jacket or sweater');
    else if (temp < 22) items.add('👕 Light layers');
    else items.add('👕 Light breathable clothing');
    if (rainProb > 0.5) items.add('☂️ Umbrella essential');
    else if (rainProb > 0.3) items.add('☂️ Pack umbrella');
    if (uv >= 6) items.add('🕶️ Sunscreen + sunglasses');
    else if (uv >= 3) items.add('🕶️ Sunglasses');
    return items.join('\n');
  }
}
