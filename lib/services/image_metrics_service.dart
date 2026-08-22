import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageMetrics {
  /// 0-100. Higher = redder/more inflamed-looking.
  final double rednessScore;

  /// 0-100. Higher = rougher/more textured surface (crusting, flaking),
  /// based on Canny edge density.
  final double textureSeverityScore;

  ImageMetrics({required this.rednessScore, required this.textureSeverityScore});

  String get rednessLabel => _label(rednessScore);
  String get textureLabel => _label(textureSeverityScore);

  static String _label(double score) {
    if (score < 33) return 'Low';
    if (score < 66) return 'Moderate';
    return 'High';
  }
}

/// Computes both metrics directly from a decoded image — pure classical
/// computer vision, no trained model involved, so this works even before
/// (or without) the MobileNetV3 model being bundled.
///
/// These scores are computed over the WHOLE framed photo, not a
/// segmented lesion region — they assume the person centered the
/// affected area per the Scan screen's framing guide. That's a real
/// limitation worth naming explicitly (e.g. in a thesis limitations
/// section): a photo with lots of healthy surrounding fur in-frame will
/// dilute both scores toward "lower" than a tightly-cropped one.
class ImageMetricsService {
  static const _workingSize = 160; // downsized for speed; both metrics are scale-invariant enough at this size

  static ImageMetrics compute(img.Image image) {
    final small = img.copyResize(image, width: _workingSize, height: _workingSize);
    return ImageMetrics(
      rednessScore: _computeRedness(small),
      textureSeverityScore: _computeTextureSeverity(small),
    );
  }

  // ==================== Redness / inflammation ====================

  /// Erythema-style redness index per pixel: how much the red channel
  /// exceeds the average of green+blue, normalized by overall brightness
  /// so it measures "how red relative to itself" rather than "how bright".
  /// Averaged over all non-extreme pixels (skips near-black shadows and
  /// near-white glare/flash spots, which aren't meaningful redness signal).
  static double _computeRedness(img.Image image) {
    double total = 0;
    int count = 0;

    for (final pixel in image) {
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      final brightness = (r + g + b) / 3;
      if (brightness < 20 || brightness > 245) continue;

      final rednessIndex = (r - (g + b) / 2) / (brightness + 1e-6);
      total += rednessIndex.clamp(0, 1); // only count pixels that lean red, not away from it
      count++;
    }

    if (count == 0) return 0;
    return ((total / count) * 100).clamp(0, 100);
  }

  // ==================== Texture / crusting severity (Canny) ====================

  /// Standard Canny pipeline: grayscale -> Gaussian blur -> Sobel
  /// gradients -> non-maximum suppression -> double threshold ->
  /// hysteresis. Edge pixel density becomes the severity score.
  ///
  /// NOTE ON CALIBRATION: raw edge density (typically a few percent to
  /// ~20% of pixels for natural photos) is scaled by `_densityScaleFactor`
  /// into a 0-100 score. That constant is a starting estimate, not
  /// empirically calibrated — see pupcheck_training/image_metrics.py,
  /// which computes real per-class average edge density across your
  /// actual dataset. Use those numbers to tune `_densityScaleFactor` so
  /// "healthy" photos land low and visibly crusted conditions land high.
  static const double _densityScaleFactor = 100 / 0.18;

  static double _computeTextureSeverity(img.Image image) {
    final w = image.width, h = image.height;
    final gray = _toGrayscale(image);
    final blurred = _gaussianBlur5x5(gray, w, h);
    final sobel = _sobel(blurred, w, h);
    final suppressed = _nonMaxSuppression(sobel.magnitude, sobel.direction, w, h);
    final edges = _doubleThresholdAndHysteresis(suppressed, w, h);

    var edgeCount = 0;
    for (final v in edges) {
      if (v != 0) edgeCount++;
    }
    final density = edgeCount / (w * h);
    return (density * _densityScaleFactor).clamp(0, 100);
  }

  static Float64List _toGrayscale(img.Image image) {
    final out = Float64List(image.width * image.height);
    var i = 0;
    for (final pixel in image) {
      // Standard luminance weighting.
      out[i++] = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
    }
    return out;
  }

  static Float64List _gaussianBlur5x5(Float64List src, int w, int h) {
    // Classic Canny-preprocessing kernel (sigma ~1.4), normalized by 159.
    const kernel = [
      [2, 4, 5, 4, 2],
      [4, 9, 12, 9, 4],
      [5, 12, 15, 12, 5],
      [4, 9, 12, 9, 4],
      [2, 4, 5, 4, 2],
    ];
    const kernelSum = 159.0;

    final out = Float64List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        double sum = 0;
        for (var ky = -2; ky <= 2; ky++) {
          for (var kx = -2; kx <= 2; kx++) {
            final sx = (x + kx).clamp(0, w - 1);
            final sy = (y + ky).clamp(0, h - 1);
            sum += src[sy * w + sx] * kernel[ky + 2][kx + 2];
          }
        }
        out[y * w + x] = sum / kernelSum;
      }
    }
    return out;
  }

  static _SobelResult _sobel(Float64List src, int w, int h) {
    const gxKernel = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const gyKernel = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    final magnitude = Float64List(w * h);
    final direction = Float64List(w * h);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        double gx = 0, gy = 0;
        for (var ky = -1; ky <= 1; ky++) {
          for (var kx = -1; kx <= 1; kx++) {
            final sx = (x + kx).clamp(0, w - 1);
            final sy = (y + ky).clamp(0, h - 1);
            final v = src[sy * w + sx];
            gx += v * gxKernel[ky + 1][kx + 1];
            gy += v * gyKernel[ky + 1][kx + 1];
          }
        }
        final idx = y * w + x;
        magnitude[idx] = math.sqrt(gx * gx + gy * gy);
        direction[idx] = math.atan2(gy, gx);
      }
    }
    return _SobelResult(magnitude, direction);
  }

  /// Thins edges to single-pixel width by keeping only local maxima along
  /// the gradient direction (quantized to 4 compass bins).
  static Float64List _nonMaxSuppression(Float64List magnitude, Float64List direction, int w, int h) {
    final out = Float64List(w * h);

    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final idx = y * w + x;
        var angle = direction[idx] * 180 / math.pi;
        if (angle < 0) angle += 180;

        double neighbor1, neighbor2;
        if (angle < 22.5 || angle >= 157.5) {
          // horizontal edge -> compare east/west
          neighbor1 = magnitude[idx - 1];
          neighbor2 = magnitude[idx + 1];
        } else if (angle < 67.5) {
          // diagonal -> compare NE/SW
          neighbor1 = magnitude[(y - 1) * w + (x + 1)];
          neighbor2 = magnitude[(y + 1) * w + (x - 1)];
        } else if (angle < 112.5) {
          // vertical edge -> compare N/S
          neighbor1 = magnitude[(y - 1) * w + x];
          neighbor2 = magnitude[(y + 1) * w + x];
        } else {
          // diagonal -> compare NW/SE
          neighbor1 = magnitude[(y - 1) * w + (x - 1)];
          neighbor2 = magnitude[(y + 1) * w + (x + 1)];
        }

        final m = magnitude[idx];
        out[idx] = (m >= neighbor1 && m >= neighbor2) ? m : 0;
      }
    }
    return out;
  }

  /// Classifies pixels as strong/weak/non-edges by threshold, then keeps
  /// weak edges only if connected (8-neighborhood, via flood fill) to a
  /// strong edge — standard Canny hysteresis.
  static Uint8List _doubleThresholdAndHysteresis(Float64List suppressed, int w, int h) {
    double maxVal = 0;
    for (final v in suppressed) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) return Uint8List(w * h);

    final highThreshold = maxVal * 0.2;
    final lowThreshold = highThreshold * 0.4;

    final out = Uint8List(w * h); // 0 = non-edge, 1 = weak, 2 = strong
    for (var i = 0; i < suppressed.length; i++) {
      if (suppressed[i] >= highThreshold) {
        out[i] = 2;
      } else if (suppressed[i] >= lowThreshold) {
        out[i] = 1;
      }
    }

    final result = Uint8List(w * h);
    final visited = Uint8List(w * h);
    final stack = <int>[];

    for (var i = 0; i < out.length; i++) {
      if (out[i] == 2 && visited[i] == 0) {
        stack.add(i);
        visited[i] = 1;
        while (stack.isNotEmpty) {
          final idx = stack.removeLast();
          result[idx] = 255;
          final x = idx % w, y = idx ~/ w;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx, ny = y + dy;
              if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
              final nIdx = ny * w + nx;
              if (visited[nIdx] == 0 && out[nIdx] != 0) {
                visited[nIdx] = 1;
                stack.add(nIdx);
              }
            }
          }
        }
      }
    }
    return result;
  }
}

class _SobelResult {
  final Float64List magnitude;
  final Float64List direction;
  _SobelResult(this.magnitude, this.direction);
}
