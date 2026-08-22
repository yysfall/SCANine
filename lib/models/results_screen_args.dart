import 'dart:typed_data';

import 'scan_result.dart';

/// Route arguments for the Results screen. The CAM overlay is only
/// available right after an on-device prediction (it isn't persisted to
/// the backend), so it's carried separately from the stored [ScanResult].
class ResultsScreenArgs {
  final ScanResult result;
  final Uint8List? camOverlayPng;

  ResultsScreenArgs({required this.result, this.camOverlayPng});
}
