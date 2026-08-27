import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/on_device_prediction.dart';

/// Thrown when the model assets aren't bundled yet (before training is
/// done) or fail to load — callers should catch this and fall back to
/// server-side prediction rather than crash.
class ModelNotAvailableException implements Exception {
  final String message;
  ModelNotAvailableException(this.message);
  @override
  String toString() => message;
}

/// Runs MobileNetV3 inference entirely on-device via TFLite, and computes
/// a Grad-CAM-equivalent heatmap (see pupcheck_training/README.md for why
/// this closed-form method is mathematically identical to gradient-based
/// Grad-CAM for this architecture) without needing autodiff, which TFLite
/// doesn't support at runtime.
class OnDevicePredictor {
  OnDevicePredictor._();
  static final OnDevicePredictor instance = OnDevicePredictor._();

  static const _modelAsset = 'assets/model/pupcheck_model.tflite';
  static const _classNamesAsset = 'assets/model/class_names.json';
  static const _camWeightsAsset = 'assets/model/cam_weights.json';
  static const _inputSize = 224;
  // Separate from _inputSize on purpose: 224x224 is a forced square,
  // required by the model, but a bad size to actually SHOW to the person
  // — it distorts non-square photos and looks blurry once stretched
  // across a phone-width display. The CAM overlay is built on a much
  // larger, aspect-ratio-preserving copy instead — see predict() below.
  static const _displayMaxDimension = 1024;

  Interpreter? _interpreter;
  List<String>? _classNames;
  List<List<double>>? _camWeights; // [channels][numClasses]

  bool get isLoaded => _interpreter != null;

  Future<void> _ensureLoaded() async {
    if (_interpreter != null) return;

    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      _interpreter!.allocateTensors();

      final classNamesRaw = await rootBundle.loadString(_classNamesAsset);
      _classNames = (jsonDecode(classNamesRaw) as List).cast<String>();

      final camWeightsRaw = await rootBundle.loadString(_camWeightsAsset);
      final camJson = jsonDecode(camWeightsRaw) as Map<String, dynamic>;
      final weightsList = camJson['weights'] as List; // [channels][numClasses]
      _camWeights = weightsList.map((row) => (row as List).map((v) => (v as num).toDouble()).toList()).toList();
    } catch (e) {
      _interpreter = null;
      _classNames = null;
      _camWeights = null;
      throw ModelNotAvailableException(
        'On-device model not available yet — train and drop it into assets/model/. ($e)',
      );
    }
  }

  /// Runs inference on an already-decoded [image] and returns the
  /// predicted class plus a CAM heatmap overlaid on a full-resolution,
  /// aspect-correct copy of the photo (not the 224x224 square used
  /// internally for model input). Takes a decoded image rather than raw
  /// bytes so callers that also need the decoded image for other purposes
  /// (e.g. ImageMetricsService) only decode once.
  Future<OnDevicePrediction> predict(img.Image decoded) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;
    final classNames = _classNames!;
    final camWeights = _camWeights!;

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // Raw 0-255 pixel values, NOT normalized — MobileNetV3's Keras
    // implementation bakes its own Rescaling layer into the model, and
    // that gets carried into the exported TFLite graph. See
    // pupcheck_training/train.py's comment on this for the full reason.
    final input = [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    ];

    final outputTensors = interpreter.getOutputTensors();
    final outputs = <int, Object>{};
    for (var i = 0; i < outputTensors.length; i++) {
      // Keyed by POSITION in this list (0, 1, 2...), not Tensor.index —
      // that's what runForMultipleInputs actually copies results into
      // internally (outputTensors[i].copyTo(outputs[i]!)), even though
      // it's easy to assume it means the tensor's graph-wide index.
      outputs[i] = _nestedZeros(outputTensors[i].shape);
    }
    interpreter.runForMultipleInputs([input], outputs);

    // Identify which output is which by rank rather than assuming a
    // fixed position — the converter doesn't guarantee output order
    // matches the Python side's outputs=[predictions, feature_maps] list.
    int? predictionsIdx;
    int? featureMapIdx;
    for (var i = 0; i < outputTensors.length; i++) {
      if (outputTensors[i].shape.length == 2) predictionsIdx = i;
      if (outputTensors[i].shape.length == 4) featureMapIdx = i;
    }
    if (predictionsIdx == null || featureMapIdx == null) {
      throw ModelNotAvailableException('Unexpected model output shapes — expected one rank-2 and one rank-4 output.');
    }

    final predsRaw = outputs[predictionsIdx] as List;
    final probabilities = (predsRaw[0] as List).map((v) => (v as num).toDouble()).toList();

    var predictedIndex = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[predictedIndex]) predictedIndex = i;
    }
    final classKey = classNames[predictedIndex];
    final confidence = probabilities[predictedIndex];

    final fmRaw = outputs[featureMapIdx] as List;
    final featureMaps = fmRaw[0] as List; // [gridH][gridW][channels]

    // Built from the ORIGINAL decoded photo, not the 224x224 square used
    // for model input — preserves aspect ratio and gives the heatmap a
    // real resolution to render at, instead of stretching a tiny image
    // up to fill the screen.
    final displayImage = _resizeForDisplay(decoded, _displayMaxDimension);

    final overlayPng = _renderCamOverlay(
      displayImage: displayImage,
      featureMaps: featureMaps,
      classWeights: camWeights.map((row) => row[predictedIndex]).toList(),
    );

    return OnDevicePrediction(
      classKey: classKey,
      confidence: confidence,
      probabilities: probabilities,
      classNames: classNames,
      overlayPng: overlayPng,
    );
  }

  /// Computes CAM = ReLU(Σ_channel weight_c * featureMap_c), normalizes
  /// it, renders it as a heatmap, and composites it over [displayImage]
  /// — a full-resolution, aspect-correct copy of the photo, NOT the
  /// distorted 224x224 square fed to the model.
  Uint8List _renderCamOverlay({
    required img.Image displayImage,
    required List featureMaps, // [gridH][gridW][channels]
    required List<double> classWeights, // [channels], already selected for the predicted class
  }) {
    final gridH = featureMaps.length;
    final gridW = (featureMaps[0] as List).length;
    final channels = ((featureMaps[0] as List)[0] as List).length;

    final cam = List.generate(gridH, (_) => List.filled(gridW, 0.0));
    double maxVal = 0;
    for (var y = 0; y < gridH; y++) {
      final row = featureMaps[y] as List;
      for (var x = 0; x < gridW; x++) {
        final channelVals = row[x] as List;
        double sum = 0;
        for (var c = 0; c < channels; c++) {
          sum += (channelVals[c] as num).toDouble() * classWeights[c];
        }
        final relu = sum < 0 ? 0.0 : sum;
        cam[y][x] = relu;
        if (relu > maxVal) maxVal = relu;
      }
    }
    if (maxVal > 0) {
      for (var y = 0; y < gridH; y++) {
        for (var x = 0; x < gridW; x++) {
          cam[y][x] = cam[y][x] / maxVal;
        }
      }
    }

    // Render the small (e.g. 7x7) CAM grid as a color heatmap, then let
    // copyResize's interpolation do the upsampling to the photo's size —
    // simpler and better-looking than hand-rolled bilinear interpolation.
    final heatSmall = img.Image(width: gridW, height: gridH);
    for (var y = 0; y < gridH; y++) {
      for (var x = 0; x < gridW; x++) {
        final t = cam[y][x];
        final color = _heatColor(t);
        heatSmall.setPixelRgba(x, y, color.$1, color.$2, color.$3, (t * 200).round()); // cap alpha so it never fully hides the photo
      }
    }
    final heatResized = img.copyResize(
      heatSmall,
      width: displayImage.width,
      height: displayImage.height,
      interpolation: img.Interpolation.cubic,
    );

    final overlay = img.Image.from(displayImage);
    img.compositeImage(overlay, heatResized);

    return Uint8List.fromList(img.encodePng(overlay));
  }

  /// Simple blue -> yellow -> red heat colormap.
  (int, int, int) _heatColor(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.5) {
      final local = t / 0.5;
      return (
        (30 + local * (255 - 30)).round(),
        (60 + local * (220 - 60)).round(),
        (200 - local * (200 - 40)).round(),
      );
    } else {
      final local = (t - 0.5) / 0.5;
      return (
        255,
        (220 - local * (220 - 40)).round(),
        (40 - local * 40).round(),
      );
    }
  }

  /// Resizes preserving aspect ratio, capping the longer side at
  /// [maxDimension] — unlike the model's forced-square resize, this
  /// never distorts the photo. Leaves already-small images untouched
  /// rather than upscaling them (upscaling would just blur further).
  img.Image _resizeForDisplay(img.Image source, int maxDimension) {
    if (source.width <= maxDimension && source.height <= maxDimension) {
      return source;
    }
    return source.width >= source.height
        ? img.copyResize(source, width: maxDimension)
        : img.copyResize(source, height: maxDimension);
  }

  dynamic _nestedZeros(List<int> shape) {
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List.generate(shape[0], (_) => _nestedZeros(shape.sublist(1)));
  }
}
