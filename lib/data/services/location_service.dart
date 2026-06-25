import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

/// Service for managing location (GPS, saved locations, favorites)
class LocationService {
  static const String _savedLocationsKey = 'saved_locations';
  static const String _currentLocationKey = 'current_location';

  /// Check and request location permissions
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current GPS position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save location to favorites
  Future<void> saveLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();

    // Remove if already exists
    locations.removeWhere((l) => l.id == location.id);
    locations.add(location);

    final jsonList = locations.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_savedLocationsKey, jsonList);
  }

  /// Remove location from favorites
  Future<void> removeLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();
    locations.removeWhere((l) => l.id == id);

    final jsonList = locations.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_savedLocationsKey, jsonList);
  }

  /// Get all saved locations
  Future<List<SavedLocation>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_savedLocationsKey) ?? [];

    return jsonList
        .map((s) => SavedLocation.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Save the currently selected location
  Future<void> setCurrentLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLocationKey, jsonEncode(location.toJson()));
  }

  /// Get the currently selected location
  Future<SavedLocation?> getCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_currentLocationKey);
    if (json == null) return null;
    return SavedLocation.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Generate a unique ID for a location
  static String generateLocationId(double lat, double lon) {
    return '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  }
}
