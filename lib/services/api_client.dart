import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../models/dog.dart';
import '../models/scan_result.dart';
import '../models/vet.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _baseUrl => Env.apiBaseUrl;

  Map<String, String> _authHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw ApiException('Not logged in — no active Supabase session.');
    }
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }

  /// Sends an image (from either the camera scan or a gallery upload) plus
  /// optional metadata to the backend and returns the prediction.
  ///
  /// Takes raw bytes rather than a `dart:io File` so this works on every
  /// platform Flutter supports, including web (where `File` doesn't exist).
  ///
  /// [mimeType] should come from the picker (e.g. `XFile.mimeType`) when
  /// available. Without an explicit Content-Type, `http` defaults multipart
  /// files to `application/octet-stream`, which the backend rejects — so
  /// we always resolve a real image content type before sending.
  ///
  /// If [predictedCondition]/[confidence]/[severity]/[description] are all
  /// provided — i.e. the app already ran on-device inference — the backend
  /// stores those instead of running its own (mock) predictor. Leave them
  /// null to let the backend predict as before.
  Future<ScanResult> analyzeScan({
    required List<int> imageBytes,
    required String filename,
    String? mimeType,
    String? locationLabel,
    List<String> symptoms = const [],
    String? predictedCondition,
    double? confidence,
    String? severity,
    String? description,
    List<Map<String, dynamic>>? differentials,
    double? rednessScore,
    double? textureSeverityScore,
  }) async {
    final uri = Uri.parse('$_baseUrl/scans/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders())
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: _resolveContentType(mimeType, filename),
      ));

    if (locationLabel != null && locationLabel.isNotEmpty) {
      request.fields['location_label'] = locationLabel;
    }
    if (symptoms.isNotEmpty) {
      request.fields['symptoms'] = symptoms.join(',');
    }
    if (predictedCondition != null) request.fields['predicted_condition'] = predictedCondition;
    if (confidence != null) request.fields['confidence'] = confidence.toString();
    if (severity != null) request.fields['severity'] = severity;
    if (description != null) request.fields['description'] = description;
    if (differentials != null) request.fields['differentials_json'] = jsonEncode(differentials);
    if (rednessScore != null) request.fields['redness_score'] = rednessScore.toString();
    if (textureSeverityScore != null) request.fields['texture_severity_score'] = textureSeverityScore.toString();

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      throw ApiException('Analyze failed (${response.statusCode}): ${response.body}');
    }
    return ScanResult.fromJson(_decode(response.body));
  }

  MediaType _resolveContentType(String? mimeType, String filename) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      return MediaType(parts[0], parts[1]);
    }
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'jpg':
      case 'jpeg':
      default:
        // Default to jpeg since this endpoint only ever receives photos,
        // and the camera/gallery pickers produce jpeg in the common case.
        return MediaType('image', 'jpeg');
    }
  }

  Future<List<ScanListItem>> listScans() async {
    final uri = Uri.parse('$_baseUrl/scans');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode != 200) {
      throw ApiException('Fetching history failed (${response.statusCode}): ${response.body}');
    }
    final list = _decodeList(response.body);
    return list.map((e) => ScanListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScanResult> getScan(String scanId) async {
    final uri = Uri.parse('$_baseUrl/scans/$scanId');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode != 200) {
      throw ApiException('Fetching scan failed (${response.statusCode}): ${response.body}');
    }
    return ScanResult.fromJson(_decode(response.body));
  }

  Future<List<Dog>> getDogs() async {
    final uri = Uri.parse('$_baseUrl/dogs');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode != 200) {
      throw ApiException('Fetching dogs failed (${response.statusCode}): ${response.body}');
    }
    return _decodeList(response.body).map((e) => Dog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Dog> createDog({
    required String name,
    String? breed,
    double? ageYears,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs');
    final response = await http.post(
      uri,
      headers: {..._authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'breed': breed, 'age_years': ageYears}),
    );

    if (response.statusCode != 201) {
      throw ApiException('Creating dog failed (${response.statusCode}): ${response.body}');
    }
    return Dog.fromJson(_decode(response.body));
  }

  Future<Dog> updateDog(
    String dogId, {
    required String name,
    String? breed,
    double? ageYears,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId');
    final response = await http.put(
      uri,
      headers: {..._authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'breed': breed, 'age_years': ageYears}),
    );

    if (response.statusCode != 200) {
      throw ApiException('Saving dog failed (${response.statusCode}): ${response.body}');
    }
    return Dog.fromJson(_decode(response.body));
  }

  Future<void> deleteDog(String dogId) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId');
    final response = await http.delete(uri, headers: _authHeaders());

    if (response.statusCode != 204) {
      throw ApiException('Deleting dog failed (${response.statusCode}): ${response.body}');
    }
  }

  /// No auth header — /vets/* isn't user-specific data.
  Future<List<VetSummary>> getNearbyVets({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final uri = Uri.parse('$_baseUrl/vets/nearby').replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius_meters': radiusMeters.toString(),
    });
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException('Fetching nearby vets failed (${response.statusCode}): ${response.body}');
    }
    final list = _decodeList(response.body);
    return list.map((e) => VetSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VetDetails> getVetDetails(String placeId) async {
    final uri = Uri.parse('$_baseUrl/vets/$placeId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException('Fetching vet details failed (${response.statusCode}): ${response.body}');
    }
    return VetDetails.fromJson(_decode(response.body));
  }

  /// Builds a URL to the backend's photo proxy — never hits Google
  /// directly from the app, so the Places API key stays server-side.
  String vetPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/vets/photo/$photoReference?max_width=$maxWidth';
  }

  Map<String, dynamic> _decode(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(String body) {
    return jsonDecode(body) as List<dynamic>;
  }
}