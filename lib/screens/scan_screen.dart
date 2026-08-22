import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/scan_submission.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _analyzing = false;

  Future<void> _capture(List<String> symptoms) async {
    final picker = ImagePicker();
    // Note: this opens the OS camera UI rather than a custom in-app
    // viewfinder. The framing overlay below is a design guide for the
    // person while they're lining up the shot in that native camera view;
    // for a fully custom live preview, swap this for the `camera` package.
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return; // user cancelled

    setState(() => _analyzing = true);
    try {
      final bytes = await picked.readAsBytes();
      final args = await submitScan(
        imageBytes: bytes,
        filename: picked.name,
        mimeType: picked.mimeType,
        symptoms: symptoms,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/results', arguments: args);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = (ModalRoute.of(context)?.settings.arguments as List<String>?) ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFF101917),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _analyzing ? null : () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 24,
                    left: 40,
                    right: 40,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'POSITIONING',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Center the affected area inside the frame, about 15 cm from the camera',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                          ),
                        ),
                        _corner(top: -2, left: -2, isTop: true, isLeft: true),
                        _corner(top: -2, right: -2, isTop: true, isLeft: false),
                        _corner(bottom: -2, left: -2, isTop: false, isLeft: true),
                        _corner(bottom: -2, right: -2, isTop: false, isLeft: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: _analyzing ? null : () => _capture(symptoms),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 5),
                      ),
                      child: Center(
                        child: _analyzing
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accent),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text('Analyzing photo…', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(10) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(10) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(10) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(10) : Radius.zero,
          ),
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
