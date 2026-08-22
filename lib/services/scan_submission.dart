import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../data/condition_info.dart';
import '../models/results_screen_args.dart';
import 'api_client.dart';
import 'image_metrics_service.dart';
import 'on_device_predictor.dart';

/// Runs the full local analysis pipeline for a captured/uploaded photo:
///   1. Decode once.
///   2. Compute redness + texture severity (classical CV, always works,
///      no trained model needed).
///   3. Try on-device MobileNetV3 inference; fall back to letting the
///      backend predict (its mock predictor, until a real model exists)
///      if the on-device model isn't bundled or inference fails.
/// Either way, the image, prediction, and the two CV scores all get sent
/// to the backend together in one call.
Future<ResultsScreenArgs> submitScan({
  required Uint8List imageBytes,
  required String filename,
  String? mimeType,
  String? locationLabel,
  List<String> symptoms = const [],
}) async {
  final decoded = img.decodeImage(imageBytes);
  final metrics = decoded != null ? ImageMetricsService.compute(decoded) : null;

  try {
    if (decoded == null) throw ModelNotAvailableException('Could not decode image.');

    final prediction = await OnDevicePredictor.instance.predict(decoded);
    final info = conditionInfoFor(prediction.classKey);
    final differentials = prediction
        .topDifferentials(count: 2)
        .map((e) => {
              'condition': conditionInfoFor(e.key).displayName,
              'confidence': e.value,
            })
        .toList();

    final result = await ApiClient.instance.analyzeScan(
      imageBytes: imageBytes,
      filename: filename,
      mimeType: mimeType,
      locationLabel: locationLabel,
      symptoms: symptoms,
      predictedCondition: info.displayName,
      confidence: prediction.confidence,
      severity: info.severity,
      description: info.description,
      differentials: differentials,
      rednessScore: metrics?.rednessScore,
      textureSeverityScore: metrics?.textureSeverityScore,
    );

    return ResultsScreenArgs(result: result, camOverlayPng: prediction.overlayPng);
  } on ModelNotAvailableException {
    // Expected until a trained model is bundled — fall back silently to
    // the backend's own prediction rather than surfacing this as an error.
    // The CV metrics still went through above regardless, since they
    // don't depend on the model at all.
    final result = await ApiClient.instance.analyzeScan(
      imageBytes: imageBytes,
      filename: filename,
      mimeType: mimeType,
      locationLabel: locationLabel,
      symptoms: symptoms,
      rednessScore: metrics?.rednessScore,
      textureSeverityScore: metrics?.textureSeverityScore,
    );
    return ResultsScreenArgs(result: result);
  }
}
