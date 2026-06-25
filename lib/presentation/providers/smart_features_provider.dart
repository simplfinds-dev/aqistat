import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/human_language.dart';
import '../../core/utils/weather_utils.dart';
import '../../data/models/weather_model.dart';
import 'weather_provider.dart';
import 'aqi_provider.dart';

/// Day rating score
enum DayRating { great, good, fair, poor, bad }

/// Day rating data
class DayRatingData {
  final DayRating rating;
  final String label;
  final String explanation;
  final double score; // 0-100

  DayRatingData({
    required this.rating,
    required this.label,
    required this.explanation,
    required this.score,
  });
}

/// What to wear recommendation
final whatToWearProvider = FutureProvider.autoDispose<String>((ref) async {
  final weather = await ref.watch(currentWeatherProvider.future);
  final hourly = await ref.watch(hourlyForecastProvider.future);

  if (weather == null) return 'Unable to generate outfit suggestion.';

  // Find max rain probability in next 12 hours
  double maxRainProb = 0;
  double maxUv = 0;
  for (final hour in hourly.take(12)) {
    if (hour.rainProbability > maxRainProb) maxRainProb = hour.rainProbability;
    if (hour.uvIndex > maxUv) maxUv = hour.uvIndex;
  }

  return HumanLanguage.whatToWear(
    tempC: weather.tempCelsius,
    feelsLike: weather.feelsLikeCelsius,
    rainProbability: maxRainProb,
    windKmh: weather.windSpeedKmh,
    uvIndex: maxUv,
  );
});

/// Umbrella reminder
final umbrellaReminderProvider = FutureProvider.autoDispose<String?>((ref) async {
  final hourly = await ref.watch(hourlyForecastProvider.future);

  if (hourly.isEmpty) return null;

  // Check if rain is expected in next 16 hours
  double maxRainProb = 0;
  String rainTime = '';

  for (final hour in hourly.take(16)) {
    if (hour.rainProbability > maxRainProb) {
      maxRainProb = hour.rainProbability;
      final hourOfDay = hour.dateTime.hour;
      final period = hourOfDay >= 12 ? 'PM' : 'AM';
      final displayHour = hourOfDay > 12 ? hourOfDay - 12 : (hourOfDay == 0 ? 12 : hourOfDay);
      rainTime = '$displayHour:00 $period';
    }
  }

  if (maxRainProb < 0.3) return null;

  return HumanLanguage.umbrellaReminder(maxRainProb, rainTime);
});

/// UV safety information
class UvSafetyInfo {
  final double uvIndex;
  final String level;
  final String recommendation;
  final int sunburnMinutes;
  final String spfRecommendation;

  UvSafetyInfo({
    required this.uvIndex,
    required this.level,
    required this.recommendation,
    required this.sunburnMinutes,
    required this.spfRecommendation,
  });
}

final uvSafetyProvider = FutureProvider.autoDispose<UvSafetyInfo?>((ref) async {
  final hourly = await ref.watch(hourlyForecastProvider.future);

  if (hourly.isEmpty) return null;

  // Find peak UV in next 12 hours
  double peakUv = 0;
  for (final hour in hourly.take(12)) {
    if (hour.uvIndex > peakUv) peakUv = hour.uvIndex;
  }

  final level = WeatherUtils.getUvDescription(peakUv);
  final sunburnTime = WeatherUtils.estimateSunburnTime(peakUv);

  String recommendation;
  String spf;
  if (peakUv <= 2) {
    recommendation = 'Low UV risk. Enjoy the outdoors freely.';
    spf = 'SPF 15 if spending extended time outside';
  } else if (peakUv <= 5) {
    recommendation = 'Moderate UV. Wear sunglasses on bright days.';
    spf = 'SPF 30 recommended';
  } else if (peakUv <= 7) {
    recommendation = 'High UV! Reduce time in the sun between 10AM-4PM.';
    spf = 'SPF 30-50 essential';
  } else if (peakUv <= 10) {
    recommendation = 'Very high UV! Minimize sun exposure. Seek shade.';
    spf = 'SPF 50+ required, reapply every 2 hours';
  } else {
    recommendation = 'Extreme UV! Avoid the sun if possible. Burns in minutes.';
    spf = 'SPF 50+ essential, stay in shade';
  }

  return UvSafetyInfo(
    uvIndex: peakUv,
    level: level,
    recommendation: recommendation,
    sunburnMinutes: sunburnTime,
    spfRecommendation: spf,
  );
});

/// Day Rating Score
final dayRatingProvider = FutureProvider.autoDispose<DayRatingData?>((ref) async {
  final weather = await ref.watch(currentWeatherProvider.future);
  final hourly = await ref.watch(hourlyForecastProvider.future);
  final aqi = await ref.watch(currentAqiProvider.future);

  if (weather == null) return null;

  double score = 100;

  // Temperature score (optimal: 18-25°C)
  if (weather.tempCelsius < 0) score -= 30;
  else if (weather.tempCelsius < 10) score -= 15;
  else if (weather.tempCelsius > 35) score -= 30;
  else if (weather.tempCelsius > 30) score -= 15;
  else if (weather.tempCelsius >= 18 && weather.tempCelsius <= 25) score += 0; // Perfect

  // Rain score
  double maxRain = 0;
  double maxUv = 0;
  for (final hour in hourly.take(12)) {
    if (hour.rainProbability > maxRain) maxRain = hour.rainProbability;
    if (hour.uvIndex > maxUv) maxUv = hour.uvIndex;
  }
  if (maxRain > 0.8) score -= 25;
  else if (maxRain > 0.5) score -= 15;
  else if (maxRain > 0.3) score -= 8;

  // UV score
  if (maxUv > 10) score -= 20;
  else if (maxUv > 7) score -= 10;

  // AQI score
  final aqiValue = aqi?.aqi ?? 50;
  if (aqiValue > 200) score -= 30;
  else if (aqiValue > 150) score -= 20;
  else if (aqiValue > 100) score -= 10;

  // Wind score
  if (weather.windSpeedKmh > 50) score -= 15;
  else if (weather.windSpeedKmh > 30) score -= 8;

  score = score.clamp(0, 100);

  // Determine rating
  DayRating rating;
  String label;
  if (score >= 80) {
    rating = DayRating.great;
    label = 'Great';
  } else if (score >= 65) {
    rating = DayRating.good;
    label = 'Good';
  } else if (score >= 45) {
    rating = DayRating.fair;
    label = 'Fair';
  } else if (score >= 25) {
    rating = DayRating.poor;
    label = 'Poor';
  } else {
    rating = DayRating.bad;
    label = 'Bad';
  }

  final explanation = HumanLanguage.dayRatingExplanation(
    rating: label,
    tempC: weather.tempCelsius,
    rainProb: maxRain,
    uvIndex: maxUv,
    aqi: aqiValue,
  );

  return DayRatingData(
    rating: rating,
    label: label,
    explanation: explanation,
    score: score,
  );
});

/// Pollen and health tips
class HealthTips {
  final String pollenLevel;
  final String humidityComfort;
  final String breathingAdvisory;
  final List<String> tips;

  HealthTips({
    required this.pollenLevel,
    required this.humidityComfort,
    required this.breathingAdvisory,
    required this.tips,
  });
}

final healthTipsProvider = FutureProvider.autoDispose<HealthTips?>((ref) async {
  final weather = await ref.watch(currentWeatherProvider.future);
  final aqi = await ref.watch(currentAqiProvider.future);

  if (weather == null) return null;

  // Humidity comfort
  String humidityComfort;
  if (weather.humidity < 30) {
    humidityComfort = 'Very dry — stay hydrated and use moisturizer.';
  } else if (weather.humidity < 50) {
    humidityComfort = 'Comfortable humidity levels.';
  } else if (weather.humidity < 70) {
    humidityComfort = 'Slightly humid — may feel sticky outdoors.';
  } else {
    humidityComfort = 'Very humid — take it easy, sweat won\'t evaporate easily.';
  }

  // Pollen (simplified — would use real pollen API in production)
  String pollenLevel;
  if (weather.tempCelsius > 15 && weather.tempCelsius < 30 && weather.humidity < 60) {
    pollenLevel = 'Moderate to High — allergy sufferers take precautions.';
  } else if (weather.rain1h != null && weather.rain1h! > 0) {
    pollenLevel = 'Low — rain has cleared the air of pollen.';
  } else {
    pollenLevel = 'Low to Moderate.';
  }

  // Breathing advisory based on AQI
  String breathingAdvisory;
  final aqiValue = aqi?.aqi ?? 50;
  if (aqiValue <= 50) {
    breathingAdvisory = 'Excellent air for breathing. No concerns.';
  } else if (aqiValue <= 100) {
    breathingAdvisory = 'Acceptable air quality. Sensitive individuals may want to limit strenuous outdoor activity.';
  } else {
    breathingAdvisory = 'Poor air quality for breathing. Consider wearing a mask outdoors.';
  }

  // Tips
  final tips = <String>[];
  if (weather.humidity > 70) tips.add('High humidity may worsen asthma symptoms');
  if (aqiValue > 100) tips.add('Consider using an indoor air purifier today');
  if (weather.tempCelsius > 30) tips.add('Drink extra water in this heat');
  if (weather.tempCelsius < 5) tips.add('Cold air can trigger respiratory issues — breathe through a scarf');
  if (tips.isEmpty) tips.add('Conditions are generally favorable for outdoor activities');

  return HealthTips(
    pollenLevel: pollenLevel,
    humidityComfort: humidityComfort,
    breathingAdvisory: breathingAdvisory,
    tips: tips,
  );
});
