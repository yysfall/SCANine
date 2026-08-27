class Differential {
  final String condition;
  final double confidence;

  Differential({required this.condition, required this.confidence});

  factory Differential.fromJson(Map<String, dynamic> json) => Differential(
        condition: json['condition'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );
}

class ScanResult {
  final String id;
  final String imageUrl;
  final String? locationLabel;
  final List<String> symptoms;
  final String predictedCondition;
  final double confidence;
  final String severity; // 'healthy' | 'mild' | 'moderate' | 'severe'
  final String description;
  final List<Differential> differentials;
  final double? rednessScore; // 0-100, classical-CV inflammation indicator
  final double? textureSeverityScore; // 0-100, Canny-edge-based crusting/roughness indicator
  final DateTime createdAt;

  ScanResult({
    required this.id,
    required this.imageUrl,
    this.locationLabel,
    required this.symptoms,
    required this.predictedCondition,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.differentials,
    this.rednessScore,
    this.textureSeverityScore,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        locationLabel: json['location_label'] as String?,
        symptoms: (json['symptoms'] as List<dynamic>? ?? []).cast<String>(),
        predictedCondition: json['predicted_condition'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        severity: json['severity'] as String,
        description: json['description'] as String,
        differentials: (json['differentials'] as List<dynamic>? ?? [])
            .map((d) => Differential.fromJson(d as Map<String, dynamic>))
            .toList(),
        rednessScore: (json['redness_score'] as num?)?.toDouble(),
        textureSeverityScore: (json['texture_severity_score'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class ScanListItem {
  final String id;
  final String imageUrl;
  final String? locationLabel;
  final String predictedCondition;
  final String severity;
  final DateTime createdAt;

  ScanListItem({
    required this.id,
    required this.imageUrl,
    this.locationLabel,
    required this.predictedCondition,
    required this.severity,
    required this.createdAt,
  });

  factory ScanListItem.fromJson(Map<String, dynamic> json) => ScanListItem(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        locationLabel: json['location_label'] as String?,
        predictedCondition: json['predicted_condition'] as String,
        severity: json['severity'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
