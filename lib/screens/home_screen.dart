import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dog.dart';
import '../models/scan_result.dart';
import '../models/vet.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/edit_dog_sheet.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loadingScans = true;
  bool _usingDemoScans = false;
  List<ScanListItem> _scans = [];

  bool _loadingDog = true;
  Dog? _dog;

  bool _loadingVets = true;
  VetSummary? _nearestVet;
  int _nearbyVetsCount = 0;

  String? _openingScanId;

  @override
  void initState() {
    super.initState();
    _loadScans();
    _loadDog();
    _loadNearestVet();
  }

  Future<void> _loadNearestVet() async {
    setState(() => _loadingVets = true);
    try {
      final position = await LocationService.getCurrentPosition();
      final vets = await ApiClient.instance.getNearbyVets(lat: position.latitude, lng: position.longitude);
      setState(() {
        _nearestVet = vets.isNotEmpty ? vets.first : null;
        _nearbyVetsCount = vets.length;
      });
    } catch (_) {
      // Location permission not granted yet, or backend/Places not
      // configured — leave the card in its empty state rather than error.
      setState(() {
        _nearestVet = null;
        _nearbyVetsCount = 0;
      });
    } finally {
      if (mounted) setState(() => _loadingVets = false);
    }
  }

  Future<void> _loadScans() async {
    setState(() => _loadingScans = true);
    try {
      final scans = await ApiClient.instance.listScans();
      setState(() {
        _scans = scans;
        _usingDemoScans = false;
      });
    } catch (_) {
      setState(() {
        _scans = [
          ScanListItem(
            id: 'demo-1',
            imageUrl: '',
            locationLabel: 'Left hind leg',
            predictedCondition: 'Acute Moist Dermatitis',
            severity: 'moderate',
            createdAt: DateTime.now(),
          ),
        ];
        _usingDemoScans = true;
      });
    } finally {
      if (mounted) setState(() => _loadingScans = false);
    }
  }

  Future<void> _loadDog() async {
    setState(() => _loadingDog = true);
    try {
      final dog = await ApiClient.instance.getMyDog();
      setState(() => _dog = dog);
    } catch (_) {
      // Leave _dog null — the card just shows an "Add your dog" state.
    } finally {
      if (mounted) setState(() => _loadingDog = false);
    }
  }

  Future<void> _openScan(ScanListItem item) async {
    if (item.id.startsWith('demo-')) {
      Navigator.pushNamed(context, '/results');
      return;
    }
    setState(() => _openingScanId = item.id);
    try {
      final full = await ApiClient.instance.getScan(item.id);
      if (!mounted) return;
      Navigator.pushNamed(context, '/results', arguments: full);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _openingScanId = null);
    }
  }

  Future<void> _editDog() async {
    final saved = await showEditDogSheet(context, current: _dog);
    if (saved != null) setState(() => _dog = saved);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty) ? fullName : (user?.email ?? 'Pet Parent');
    final firstName = displayName.split(RegExp(r'\s+')).first;
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : 'PC';

    final needsAttention = _scans.where((s) => s.severity == 'moderate' || s.severity == 'severe').length;

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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GOOD MORNING', style: AppText.eyebrow()),
                            const SizedBox(height: 4),
                            Text('Hi, $firstName 👋', style: AppText.display(size: 20)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 19,
                            backgroundColor: AppColors.accentSoft,
                            child: Text(initials,
                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Scan CTA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEW SCAN', style: AppText.eyebrow(color: AppColors.accent)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 220,
                            child: Text(
                              _dog != null ? "Spotted something on ${_dog!.name}'s coat?" : 'Spotted something on your dog\'s coat?',
                              style: AppText.display(size: 19, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 220,
                            child: Text('Scan the area and get an instant skin condition prediction.',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                            onPressed: () => Navigator.pushNamed(context, '/analyze'),
                            child: const Text('Start Scan →'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stats row
                    Row(
                      children: [
                        _StatBox(num: _loadingScans ? '—' : '${_scans.length}', label: 'Total scans'),
                        const SizedBox(width: 10),
                        _StatBox(num: _loadingScans ? '—' : '$needsAttention', label: 'Needs attention'),
                        const SizedBox(width: 10),
                        _StatBox(num: _loadingVets ? '—' : '$_nearbyVetsCount', label: 'Vets nearby'),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // My dog
                    _SectionTitle(title: 'My dog', onSeeAll: null),
                    const SizedBox(height: 10),
                    _loadingDog
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : GestureDetector(
                            onTap: _editDog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                                    child: const Center(child: Text('🐶', style: TextStyle(fontSize: 20))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_dog?.name ?? 'Add your dog', style: AppText.body(size: 14, w: FontWeight.w700)),
                                        Text(_dog?.subtitle ?? 'Tap to add name, breed, and age', style: AppText.muted(size: 11)),
                                      ],
                                    ),
                                  ),
                                  Text(_dog == null ? 'Add' : 'Edit',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Recent scan
                    _SectionTitle(title: 'Recent scan', onSeeAll: () => Navigator.pushNamed(context, '/history')),
                    const SizedBox(height: 10),
                    if (_usingDemoScans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("Showing sample data — couldn't reach the server.", style: AppText.muted(size: 11.5)),
                      ),
                    if (_loadingScans)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_scans.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text('No scans yet — start your first one above.', style: AppText.muted(size: 12.5)),
                      )
                    else
                      _recentScanCard(_scans.first),
                    const SizedBox(height: 20),

                    // Nearby vets
                    _SectionTitle(title: 'Nearby vets', onSeeAll: () => Navigator.pushNamed(context, '/vets')),
                    const SizedBox(height: 10),
                    if (_loadingVets)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_nearestVet == null)
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/vets'),
                        child: Text(
                          'Enable location to see clinics near you.',
                          style: AppText.muted(size: 12.5),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/vet-details', arguments: _nearestVet!.placeId),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Text('📍', style: TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_nearestVet!.name, style: AppText.body(size: 13, w: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (_nearestVet!.distanceLabel.isNotEmpty) '${_nearestVet!.distanceLabel} away',
                                      if (_nearestVet!.openNow != null) (_nearestVet!.openNow! ? 'Open now' : 'Closed'),
                                    ].join(' · '),
                                    style: AppText.muted(size: 11),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PupCheckBottomNav(current: 'home'),
          ],
        ),
      ),
    );
  }

  Widget _recentScanCard(ScanListItem item) {
    final isOpening = _openingScanId == item.id;
    return GestureDetector(
      onTap: isOpening ? null : () => _openScan(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('🐾', style: TextStyle(fontSize: 20))),
                    )
                  : const Center(child: Text('🐾', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.locationLabel ?? 'Scan', style: AppText.body(size: 13, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM d, h:mm a').format(item.createdAt), style: AppText.muted(size: 11)),
                ],
              ),
            ),
            //if (isOpening)
              //const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            //else
              //_severityPill(item.severity),
          ],
        ),
      ),
    );
  }

  Widget _severityPill(String severity) {
    switch (severity) {
      case 'healthy':
        return Pill.success('Healthy');
      case 'mild':
        return Pill.accent('Mild');
      default:
        return Pill.alert(severity == 'severe' ? 'Needs attention' : 'Moderate');
    }
  }
}

class _StatBox extends StatelessWidget {
  final String num;
  final String label;
  const _StatBox({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(num, style: AppText.display(size: 22, color: AppColors.primary)),
            Text(label, style: AppText.muted(size: 11)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppText.display(size: 16)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
      ],
    );
  }
}
