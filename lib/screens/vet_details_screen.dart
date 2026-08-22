import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vet.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class VetDetailsScreen extends StatefulWidget {
  const VetDetailsScreen({super.key});

  @override
  State<VetDetailsScreen> createState() => _VetDetailsScreenState();
}

class _VetDetailsScreenState extends State<VetDetailsScreen> {
  bool _loading = true;
  String? _error;
  VetDetails? _vet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vet == null && _loading) {
      final placeId = ModalRoute.of(context)?.settings.arguments as String?;
      if (placeId == null) {
        setState(() {
          _loading = false;
          _error = 'No clinic selected.';
        });
      } else {
        _load(placeId);
      }
    }
  }

  Future<void> _load(String placeId) async {
    try {
      final vet = await ApiClient.instance.getVetDetails(placeId);
      if (!mounted) return;
      setState(() => _vet = vet);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not load clinic details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _call() async {
    final phone = _vet?.phoneNumber;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _directions() async {
    final vet = _vet;
    if (vet == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${vet.lat},${vet.lng}&destination_place_id=${vet.placeId}',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _vet == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const SizedBox(height: 40),
                Center(child: Text(_error ?? 'Something went wrong.', style: AppText.muted())),
              ],
            ),
          ),
        ),
      );
    }

    final vet = _vet!;

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              vet.photoReference != null
                  ? Image.network(
                      ApiClient.instance.vetPhotoUrl(vet.photoReference!),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 190, color: const Color(0xFFCFE0D3)),
                    )
                  : Container(height: 190, width: double.infinity, color: const Color(0xFFCFE0D3)),
              Positioned(
                top: 48,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
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
                  if (vet.openNow != null)
                    Pill(
                      text: vet.openNow! ? 'Open now' : 'Closed',
                      fg: vet.openNow! ? AppColors.success : AppColors.alert,
                      bg: vet.openNow! ? AppColors.successSoft : AppColors.alertSoft,
                    ),
                  const SizedBox(height: 8),
                  Text(vet.name, style: AppText.display(size: 19)),
                  const SizedBox(height: 4),
                  if (vet.rating != null)
                    Row(
                      children: [
                        Text('★ ${vet.rating!.toStringAsFixed(1)}',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        const SizedBox(width: 4),
                        if (vet.userRatingsTotal != null)
                          Text('(${vet.userRatingsTotal} reviews)', style: AppText.muted(size: 12.5)),
                      ],
                    ),
                  if (vet.address != null) ...[
                    const SizedBox(height: 4),
                    Text(vet.address!, style: AppText.muted(size: 12.5)),
                  ],
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: vet.phoneNumber != null ? _call : null,
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _directions,
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (vet.openingHours.isNotEmpty)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hours', style: AppText.body(size: 13, w: FontWeight.w700)),
                          const SizedBox(height: 4),
                          for (var i = 0; i < vet.openingHours.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(vet.openingHours[i], style: AppText.body(size: 12.5)),
                            ),
                        ],
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
}
