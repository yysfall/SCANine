class Dog {
  final String id;
  final String name;
  final String? breed;
  final double? ageYears;
  final DateTime updatedAt;

  Dog({
    required this.id,
    required this.name,
    this.breed,
    this.ageYears,
    required this.updatedAt,
  });

  factory Dog.fromJson(Map<String, dynamic> json) => Dog(
        id: json['id'] as String,
        name: json['name'] as String,
        breed: json['breed'] as String?,
        ageYears: (json['age_years'] as num?)?.toDouble(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Short display line, e.g. "Golden Retriever · 4 years old".
  String get subtitle {
    final parts = <String>[
      if (breed != null && breed!.isNotEmpty) breed!,
      if (ageYears != null) '${ageYears!.toStringAsFixed(ageYears! % 1 == 0 ? 0 : 1)} years old',
    ];
    return parts.isEmpty ? 'Tap to add details' : parts.join(' · ');
  }
}
