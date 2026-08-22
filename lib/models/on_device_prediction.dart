import 'dart:typed_data';

class OnDevicePrediction {
  final String classKey; // snake_case, e.g. "acute_moist_dermatitis"
  final double confidence;
  final List<double> probabilities; // aligned with classNames, same order
  final List<String> classNames;
  final Uint8List overlayPng; // original photo with the CAM heatmap composited on top

  OnDevicePrediction({
    required this.classKey,
    required this.confidence,
    required this.probabilities,
    required this.classNames,
    required this.overlayPng,
  });

  /// Top differentials excluding the predicted class itself, for the
  /// Results screen's "Other possibilities" section.
  List<MapEntry<String, double>> topDifferentials({int count = 2}) {
    final entries = <MapEntry<String, double>>[];
    for (var i = 0; i < classNames.length; i++) {
      if (classNames[i] == classKey) continue;
      entries.add(MapEntry(classNames[i], probabilities[i]));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).toList();
  }
}
