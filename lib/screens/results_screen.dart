import 'package:flutter/material.dart';
import '../models/results_screen_args.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final real = args is ResultsScreenArgs ? args.result : args as ScanResult?;
    final camOverlay = args is ResultsScreenArgs ? args.camOverlayPng : null;

    // Demo fallback so this screen still looks right when reached from a
    // tab/tap that isn't wired to a live scan yet (e.g. Home's hardcoded
    // "recent scan" preview card).
    final title = real?.locationLabel ?? 'Left hind leg';
    final condition = real?.predictedCondition ?? 'Acute Moist Dermatitis';
    final confidence = real?.confidence ?? 0.78;
    final description = real?.description ??
        "A red, moist, irritated patch that develops quickly, often from persistent licking or scratching. "
            "It can worsen fast and typically benefits from a vet's evaluation within a few days.";
    final differentials = real?.differentials ??
        [
          Differential(condition: 'Allergic dermatitis', confidence: 0.14),
          Differential(condition: 'Ringworm', confidence: 0.08),
        ];
    final rednessScore = real?.rednessScore ?? 62;
    final textureSeverityScore = real?.textureSeverityScore ?? 38;

    return Scaffold(
      body: Column(
        children: [
          // Hero image with back button + caption
          Stack(
            children: [
              if (camOverlay != null)
                Image.memory(camOverlay, height: 220, width: double.infinity, fit: BoxFit.cover)
              else if (real != null)
                Image.network(
                  real.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 220, color: const Color(0xFFDDBF9A)),
                )
              else
                Container(height: 220, width: double.infinity, color: const Color(0xFFDDBF9A)),
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC101917)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 48,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(camOverlay != null ? 'AI FOCUS AREA' : 'SCAN COMPLETE', style: AppText.eyebrow()),
                    Text(title, style: AppText.display(size: 18, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ConfidenceRing(percent: confidence),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(condition, style: AppText.display(size: 17)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Image analysis', style: AppText.body(size: 13, w: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Measured directly from the photo, independent of the condition prediction above.',
                          style: AppText.muted(size: 11),
                        ),
                        const SizedBox(height: 12),
                        _metricRow(
                          'Redness (inflammation)',
                          rednessScore,
                          AppColors.alert,
                          detectedText: 'Redness detected',
                          notDetectedText: 'No significant redness detected',
                        ),
                        const SizedBox(height: 14),
                        _metricRow(
                          'Texture severity (crusting)',
                          textureSeverityScore,
                          AppColors.accent,
                          detectedText: 'Texture and roughness detected',
                          notDetectedText: 'No significant texture or roughness detected',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (camOverlay != null) ...[
                    _card(
                      child: Row(
                        children: [
                          const Icon(Icons.center_focus_strong, size: 18, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Highlighted areas show what most influenced this prediction (Grad-CAM).',
                              style: AppText.muted(size: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (differentials.isNotEmpty) ...[
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Other possibilities', style: AppText.body(size: 13, w: FontWeight.w700)),
                          const SizedBox(height: 10),
                          for (final d in differentials) _diffRow(d.condition, d.confidence),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What this means', style: AppText.body(size: 13, w: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(description, style: AppText.muted(size: 12.5).copyWith(height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/vets'),
                      child: const Text('Find a Nearby Vet'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/history', (r) => false),
                      // The scan is already saved server-side by /scans/analyze,
                      // so this button is just a "done, take me to History" action.
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityPill(String severity) {
    switch (severity) {
      case 'healthy':
        return Pill.success('Healthy');
      case 'mild':
        return Pill.accent('Mild concern');
      case 'severe':
        return Pill.alert('Needs attention soon');
      case 'moderate':
      default:
        return Pill.alert('Moderate concern');
    }
  }

  // A score at or above this counts as "detected" — matches the existing
  // Low/Moderate/High boundary already used for the qualitative label, so
  // "detected" lines up with Moderate or High, not just High alone.
  static const double _detectionThreshold = 33.0;

  Widget _metricRow(
    String label,
    double score,
    Color barColor, {
    required String detectedText,
    required String notDetectedText,
  }) {
    final qualitativeLabel = score < 33 ? 'Low' : (score < 66 ? 'Moderate' : 'High');
    final detected = score >= _detectionThreshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(size: 12.5, w: FontWeight.w600)),
            Text('$qualitativeLabel · ${score.round()}/100', style: AppText.muted(size: 11.5, w: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0, 1),
            minHeight: 6,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              detected ? Icons.check_circle : Icons.check_circle_outline,
              size: 14,
              color: detected ? barColor : AppColors.inkSoft,
            ),
            const SizedBox(width: 5),
            Text(
              detected ? detectedText : notDetectedText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: detected ? barColor : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }

  Widget _diffRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: AppText.body(size: 13))),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
          Text('${(value * 100).round()}%', style: AppText.muted(size: 12)),
        ],
      ),
    );
  }
}

class _ConfidenceRing extends StatelessWidget {
  final double percent;
  const _ConfidenceRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 6,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(percent * 100).round()}%', style: AppText.display(size: 13)),
                Text('MATCH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
