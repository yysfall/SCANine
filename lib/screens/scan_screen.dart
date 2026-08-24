import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/scan_submission.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ============================================================
  // INITIALIZE CAMERA
  // ============================================================

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint('No cameras available.');
        return;
      }

      // Prefer the back camera.
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;

      _initializeControllerFuture = controller.initialize();

      await _initializeControllerFuture;

      // Lock the camera to portrait mode.
      await controller.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      debugPrint(
        'Camera aspect ratio: ${controller.value.aspectRatio}',
      );

      debugPrint(
        'Camera preview size: ${controller.value.previewSize}',
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to access camera: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // CAPTURE IMAGE
  // ============================================================

  Future<void> _capture(List<String> symptoms) async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _analyzing) {
      return;
    }

    setState(() {
      _analyzing = true;
    });

    try {
      // Take the picture using the in-app camera.
      final XFile picked = await controller.takePicture();

      // Read image bytes.
      final bytes = await picked.readAsBytes();

      // Submit to your backend.
      final args = await submitScan(
        imageBytes: bytes,
        filename: picked.name,
        mimeType: 'image/jpeg',
        symptoms: symptoms,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/results',
        arguments: args,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analysis failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _analyzing = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE CAMERA
  // ============================================================

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final symptoms =
        (ModalRoute.of(context)?.settings.arguments as List<String>?) ??
            const [];

    final controller = _cameraController;

    final cameraReady =
        controller != null &&
        controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraReady
          ? Stack(
              fit: StackFit.expand,
              children: [
                // ========================================================
                // FULL SCREEN CAMERA
                // ========================================================

                Positioned.fill(
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: controller.value.previewSize!.height,
                        height: controller.value.previewSize!.width,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),

                // ========================================================
                // SUBTLE DARK OVERLAY
                // ========================================================

                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),

                // ========================================================
                // TOP BACK BUTTON
                // ========================================================

                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _analyzing
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ),

                // ========================================================
                // POSITIONING INSTRUCTIONS
                // ========================================================

                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 40,
                  right: 40,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ========================================================
                // CENTER POSITIONING FRAME
                // ========================================================

                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        // Main frame border
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),

                        // Top-left corner
                        _corner(
                          top: -2,
                          left: -2,
                          isTop: true,
                          isLeft: true,
                        ),

                        // Top-right corner
                        _corner(
                          top: -2,
                          right: -2,
                          isTop: true,
                          isLeft: false,
                        ),

                        // Bottom-left corner
                        _corner(
                          bottom: -2,
                          left: -2,
                          isTop: false,
                          isLeft: true,
                        ),

                        // Bottom-right corner
                        _corner(
                          bottom: -2,
                          right: -2,
                          isTop: false,
                          isLeft: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // ========================================================
                // CAMERA CAPTURE BUTTON
                // ========================================================

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 30,
                  child: Center(
                    child: GestureDetector(
                      onTap: _analyzing
                          ? null
                          : () => _capture(symptoms),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 5,
                          ),
                        ),
                        child: Center(
                          child: _analyzing
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.accent,
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ========================================================
                // ANALYZING MESSAGE
                // ========================================================

                if (_analyzing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom:
                        MediaQuery.of(context).padding.bottom + 8,
                    child: const Text(
                      'Analyzing photo…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            ),
    );
  }

  // ============================================================
  // FRAME CORNERS
  // ============================================================

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
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
            topLeft: isTop && isLeft
                ? const Radius.circular(10)
                : Radius.zero,
            topRight: isTop && !isLeft
                ? const Radius.circular(10)
                : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(10)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(10)
                : Radius.zero,
          ),
          border: Border(
            top: isTop
                ? const BorderSide(
                    color: AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(
                    color: AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(
                    color: AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(
                    color: AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}