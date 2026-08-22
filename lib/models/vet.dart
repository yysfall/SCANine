class VetSummary {
  final String placeId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  final double? distanceMeters;

  VetSummary({
    required this.placeId,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
    this.distanceMeters,
  });

  factory VetSummary.fromJson(Map<String, dynamic> json) => VetSummary(
        placeId: json['place_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
        userRatingsTotal: json['user_ratings_total'] as int?,
        openNow: json['open_now'] as bool?,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      );

  String get distanceLabel {
    if (distanceMeters == null) return '';
    final km = distanceMeters! / 1000;
    return km < 1 ? '${distanceMeters!.round()} m' : '${km.toStringAsFixed(1)} km';
  }
}

class VetDetails {
  final String placeId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  final String? phoneNumber;
  final List<String> openingHours;
  final String? photoReference;

  VetDetails({
    required this.placeId,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
    this.phoneNumber,
    required this.openingHours,
    this.photoReference,
  });

  factory VetDetails.fromJson(Map<String, dynamic> json) => VetDetails(
        placeId: json['place_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
        userRatingsTotal: json['user_ratings_total'] as int?,
        openNow: json['open_now'] as bool?,
        phoneNumber: json['phone_number'] as String?,
        openingHours: (json['opening_hours'] as List? ?? []).cast<String>(),
        photoReference: json['photo_reference'] as String?,
      );
}
