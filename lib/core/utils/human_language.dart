import 'dart:math';

/// Human-language generation engine
/// Converts raw weather data into natural, conversational sentences
class HumanLanguage {
  HumanLanguage._();

  /// Generate a human-readable weather summary for current conditions
  static String currentWeatherSummary({
    required double tempC,
    required String condition,
    required double feelsLike,
    required int humidity,
    required double windKmh,
    required double rainProbability,
  }) {
    final parts = <String>[];

    // Temperature feeling
    parts.add(_temperatureFeeling(tempC, feelsLike));

    // Condition description
    parts.add(_conditionDescription(condition));

    // Rain warning if applicable
    if (rainProbability > 0.4) {
      parts.add(_rainWarning(rainProbability));
    }

    // Wind note if significant
    if (windKmh > 20) {
      parts.add(_windNote(windKmh));
    }

    return parts.join(' ');
  }

  /// Generate a daily summary
  static String dailySummary({
    required double highC,
    required double lowC,
    required String dominantCondition,
    required double maxRainProb,
    required double maxUv,
    required int aqi,
  }) {
    final buffer = StringBuffer();

    // Temperature range description
    if ((highC - lowC) > 10) {
      buffer.write('Big temperature swing today — from ${lowC.round()}° up to ${highC.round()}°. ');
    } else {
      buffer.write('Temperatures between ${lowC.round()}° and ${highC.round()}°. ');
    }

    // Condition
    buffer.write(_dayConditionSummary(dominantCondition, maxRainProb));

    // UV warning
    if (maxUv >= 8) {
      buffer.write(' UV is very high — sunscreen is essential.');
    } else if (maxUv >= 6) {
      buffer.write(' UV peaks in the high range — wear sunscreen outdoors.');
    }

    // AQI note
    if (aqi > 100) {
      buffer.write(' Air quality is concerning today — limit outdoor exertion.');
    }

    return buffer.toString();
  }

  /// Outfit suggestion based on weather
  static String whatToWear({
    required double tempC,
    required double feelsLike,
    required double rainProbability,
    required double windKmh,
    required double uvIndex,
  }) {
    final items = <String>[];

    // Base layer
    if (feelsLike < 0) {
      items.add('Heavy winter coat, thermal layers, gloves, and a warm hat');
    } else if (feelsLike < 10) {
      items.add('Warm jacket and layers');
    } else if (feelsLike < 18) {
      items.add('Light jacket or sweater');
    } else if (feelsLike < 25) {
      items.add('T-shirt and light trousers');
    } else {
      items.add('Light, breathable clothing');
    }

    // Rain gear
    if (rainProbability > 0.7) {
      items.add('definitely bring an umbrella and waterproof shoes');
    } else if (rainProbability > 0.4) {
      items.add('pack an umbrella just in case');
    }

    // Wind
    if (windKmh > 40) {
      items.add('a windbreaker would help');
    }

    // Sun protection
    if (uvIndex >= 6) {
      items.add('sunglasses and sunscreen (SPF 30+)');
    } else if (uvIndex >= 3) {
      items.add('sunglasses recommended');
    }

    if (items.length == 1) return items.first + '.';
    final last = items.removeLast();
    return '${items.join(", ")}, and $last.';
  }

  /// Umbrella reminder message
  static String umbrellaReminder(double maxRainProb, String rainTime) {
    if (maxRainProb > 0.8) {
      return 'Rain is very likely around $rainTime today. Definitely bring an umbrella!';
    } else if (maxRainProb > 0.5) {
      return 'There\'s a good chance of rain around $rainTime. An umbrella would be wise.';
    }
    return 'Slight chance of rain around $rainTime. You might want an umbrella.';
  }

  /// Day rating explanation
  static String dayRatingExplanation({
    required String rating,
    required double tempC,
    required double rainProb,
    required double uvIndex,
    required int aqi,
  }) {
    switch (rating) {
      case 'Great':
        return 'Beautiful day ahead! Comfortable temperature, low rain risk, and good air quality.';
      case 'Good':
        return 'Solid day overall. A few minor things to watch but nothing that should stop you.';
      case 'Fair':
        return 'Decent day with some caveats — check the details before making outdoor plans.';
      case 'Poor':
        return 'Not the best day for outdoor activities. Consider rescheduling if possible.';
      case 'Bad':
        return 'Challenging conditions today. Best to stay indoors or take precautions if going out.';
      default:
        return 'Check the detailed forecast for today.';
    }
  }

  // === PRIVATE HELPERS ===

  static String _temperatureFeeling(double tempC, double feelsLike) {
    final diff = (feelsLike - tempC).abs();
    if (diff < 2) {
      return _simpleTemp(tempC);
    }
    if (feelsLike > tempC) {
      return 'It\'s ${tempC.round()}° but feels more like ${feelsLike.round()}° with the humidity.';
    }
    return 'It\'s ${tempC.round()}° but feels colder at ${feelsLike.round()}° with the wind.';
  }

  static String _simpleTemp(double tempC) {
    if (tempC < 0) return 'It\'s freezing at ${tempC.round()}°.';
    if (tempC < 10) return 'It\'s quite cold at ${tempC.round()}°.';
    if (tempC < 18) return 'A cool ${tempC.round()}° right now.';
    if (tempC < 25) return 'A comfortable ${tempC.round()}° right now.';
    if (tempC < 32) return 'It\'s warm at ${tempC.round()}°.';
    if (tempC < 38) return 'It\'s hot at ${tempC.round()}°.';
    return 'Extreme heat at ${tempC.round()}° — stay hydrated!';
  }

  static String _conditionDescription(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Skies are clear and bright.';
      case 'clouds':
      case 'cloudy':
        return 'Clouds are hanging around.';
      case 'rain':
      case 'light rain':
        return 'Light rain is falling.';
      case 'heavy rain':
        return 'Heavy rain is coming down.';
      case 'drizzle':
        return 'A light drizzle in the air.';
      case 'thunderstorm':
        return 'Thunderstorms in the area — stay safe.';
      case 'snow':
        return 'Snow is falling.';
      case 'mist':
      case 'fog':
        return 'Visibility is reduced with fog.';
      case 'haze':
        return 'Hazy conditions today.';
      default:
        return 'Current conditions: $condition.';
    }
  }

  static String _rainWarning(double probability) {
    final percent = (probability * 100).round();
    if (probability > 0.8) return 'Rain is almost certain ($percent% chance).';
    if (probability > 0.6) return 'High chance of rain ($percent%).';
    return 'Some chance of rain ($percent%).';
  }

  static String _windNote(double windKmh) {
    if (windKmh > 60) return 'Strong winds at ${windKmh.round()} km/h — be careful outdoors.';
    if (windKmh > 40) return 'Quite windy at ${windKmh.round()} km/h.';
    return 'A noticeable breeze at ${windKmh.round()} km/h.';
  }

  static String _dayConditionSummary(String condition, double rainProb) {
    if (rainProb > 0.7) return 'Expect rain through much of the day — keep an umbrella handy.';
    if (rainProb > 0.4) return 'Some rain is possible — maybe keep an umbrella nearby.';
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Clear skies throughout — enjoy the sunshine!';
      case 'clouds':
        return 'Mostly cloudy skies expected.';
      case 'snow':
        return 'Snow expected — dress warmly and watch your step.';
      default:
        return 'Mixed conditions expected throughout the day.';
    }
  }
}
