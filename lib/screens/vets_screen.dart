import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/vet.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class VetsScreen extends StatefulWidget {
  const VetsScreen({super.key});

  @override
  State<VetsScreen> createState() => _VetsScreenState();
}

class _VetsScreenState extends State<VetsScreen> {
  bool _loading = true;
  String? _error;
  Position? _userPosition;
  List<VetSummary> _vets = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    print('VETS: Starting location request...');

    final position = await LocationService.getCurrentPosition();

    print('VETS: Location received!');
    print('VETS: Latitude = ${position.latitude}');
    print('VETS: Longitude = ${position.longitude}');

    print('VETS: Requesting nearby vets from API...');

    final vets = await ApiClient.instance.getNearbyVets(
      lat: position.latitude,
      lng: position.longitude,
    );

    print('VETS: API returned ${vets.length} vets');

    if (!mounted) return;

    setState(() {
      _userPosition = position;
      _vets = vets;
    });
  } on LocationException catch (e) {
    print('VETS LOCATION ERROR: ${e.message}');

    if (mounted) {
      setState(() => _error = e.message);
    }
  } on ApiException catch (e) {
    print('VETS API ERROR: ${e.message}');

    if (mounted) {
      setState(() => _error = e.message);
    }
  } catch (e) {
    print('VETS UNKNOWN ERROR: $e');

    if (mounted) {
      setState(() => _error = 'Could not load nearby vets right now.');
    }
  } finally {
    print('VETS: Finished loading');

    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  Set<Marker> get _markers {
    if (_userPosition == null) return {};
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('you'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };
    for (final v in _vets) {
      markers.add(Marker(
        markerId: MarkerId(v.placeId),
        position: LatLng(v.lat, v.lng),
        infoWindow: InfoWindow(title: v.name, snippet: v.address),
        onTap: () => Navigator.pushNamed(context, '/vet-details', arguments: v.placeId),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nearby Vets', style: AppText.display(size: 20)),
                        IconButton(
                          onPressed: _loading ? null : _load,
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.alertSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: AppColors.alert),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: TextStyle(color: AppColors.alert, fontSize: 12.5))),
                          ],
                        ),
                      ),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_userPosition != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                              zoom: 13,
                            ),
                            markers: _markers,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onMapCreated: (c) => _mapController = c,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_vets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No vet clinics found nearby.', style: AppText.muted())),
                        )
                      else
                        for (final v in _vets) _vetCard(context, v),
                    ],
                  ],
                ),
              ),
            ),
            const PupCheckBottomNav(current: 'vets'),
          ],
        ),
      ),
    );
  }

  Widget _vetCard(BuildContext context, VetSummary v) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/vet-details', arguments: v.placeId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🏥', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name, style: AppText.body(size: 13.5, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  if (v.rating != null)
                    Row(
                      children: [
                        Text('★ ${v.rating!.toStringAsFixed(1)}',
                            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        if (v.userRatingsTotal != null)
                          Text('(${v.userRatingsTotal})', style: AppText.muted(size: 11)),
                      ],
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (v.openNow != null)
                        Text(
                          v.openNow! ? 'Open now' : 'Closed',
                          style: TextStyle(
                            color: v.openNow! ? AppColors.success : AppColors.alert,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (v.distanceLabel.isNotEmpty) Text(' · ${v.distanceLabel}', style: AppText.muted(size: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
