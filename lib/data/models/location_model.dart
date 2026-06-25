/// Saved location model
class SavedLocation {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final double lat;
  final double lon;
  final bool isCurrent;
  final bool isFavorite;
  final DateTime? lastUpdated;

  SavedLocation({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.lat,
    required this.lon,
    this.isCurrent = false,
    this.isFavorite = false,
    this.lastUpdated,
  });

  SavedLocation copyWith({
    String? id,
    String? name,
    String? country,
    String? countryCode,
    double? lat,
    double? lon,
    bool? isCurrent,
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      isCurrent: isCurrent ?? this.isCurrent,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'countryCode': countryCode,
      'lat': lat,
      'lon': lon,
      'isCurrent': isCurrent,
      'isFavorite': isFavorite,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      isCurrent: json['isCurrent'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }
}
