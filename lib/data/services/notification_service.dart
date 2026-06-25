import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

/// Smart notification service — context-aware, not spammy
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification system
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Severe Weather Channel (High priority)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.severeWeatherChannel,
        'Severe Weather Alerts',
        description: 'Critical weather warnings that need immediate attention',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // AQI Alert Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.aqiAlertChannel,
        'Air Quality Alerts',
        description: 'Notifications when air quality reaches unhealthy levels',
        importance: Importance.defaultImportance,
      ),
    );

    // Umbrella Reminder Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.umbrellaReminderChannel,
        'Umbrella Reminders',
        description: 'Morning reminders when rain is expected',
        importance: Importance.defaultImportance,
      ),
    );

    // UV Alert Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.uvAlertChannel,
        'UV Alerts',
        description: 'Notifications when UV index reaches dangerous levels',
        importance: Importance.defaultImportance,
      ),
    );

    // Daily Forecast Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.dailyForecastChannel,
        'Daily Forecast',
        description: 'Daily weather summary notification',
        importance: Importance.low,
      ),
    );
  }

  /// Show a severe weather alert
  Future<void> showSevereWeatherAlert({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.severeWeatherChannel,
          'Severe Weather Alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFF44336),
        ),
      ),
    );
  }

  /// Show umbrella reminder
  Future<void> showUmbrellaReminder(String message) async {
    await _notifications.show(
      2000,
      '☂️ Umbrella Reminder',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.umbrellaReminderChannel,
          'Umbrella Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Show AQI alert
  Future<void> showAqiAlert({
    required int aqiValue,
    required String message,
  }) async {
    await _notifications.show(
      3000,
      '🌫️ Air Quality Alert — AQI $aqiValue',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.aqiAlertChannel,
          'Air Quality Alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Show UV alert
  Future<void> showUvAlert({
    required double uvIndex,
    required String message,
  }) async {
    await _notifications.show(
      4000,
      '☀️ UV Alert — Index ${uvIndex.toStringAsFixed(1)}',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.uvAlertChannel,
          'UV Alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Show daily forecast summary
  Future<void> showDailyForecast({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      5000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.dailyForecastChannel,
          'Daily Forecast',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
    // This would be connected to a navigation service in production
  }
}
