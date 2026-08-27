import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dog.dart';
import '../models/scan_result.dart';
import '../models/vet.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==============================================================
  // SCANS
  // ==============================================================

  bool _loadingScans = true;
  bool _usingDemoScans = false;
  List<ScanListItem> _scans = [];

  // ==============================================================
  // DOGS
  // ==============================================================

  bool _loadingDogs = true;
  List<Dog> _dogs = [];
  Dog? _selectedDog;

  // ==============================================================
  // VETS
  // ==============================================================

  bool _loadingVets = true;
  VetSummary? _nearestVet;
  int _nearbyVetsCount = 0;

  String? _openingScanId;

  @override
  void initState() {
    super.initState();

    _loadScans();
    _loadDogs();
    _loadNearestVet();
  }

  // ==============================================================
  // LOAD DOGS
  // ==============================================================

  Future<void> _loadDogs() async {
    setState(() => _loadingDogs = true);

    try {
      final dogs = await ApiClient.instance.getDogs();

      if (!mounted) return;

      setState(() {
        _dogs = dogs;

        if (dogs.isEmpty) {
          _selectedDog = null;
        } else {
          // Keep the currently selected dog if it still exists.
          if (_selectedDog != null) {
            final matchingDog = dogs.where(
              (dog) => dog.id == _selectedDog!.id,
            );

            _selectedDog =
                matchingDog.isNotEmpty ? matchingDog.first : dogs.first;
          } else {
            _selectedDog = dogs.first;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _dogs = [];
        _selectedDog = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDogs = false);
      }
    }
  }

  // ==============================================================
  // LOAD SCANS
  // ==============================================================

  Future<void> _loadScans() async {
    setState(() => _loadingScans = true);

    try {
      final scans = await ApiClient.instance.listScans();

      if (!mounted) return;

      setState(() {
        _scans = scans;
        _usingDemoScans = false;
      });
    } catch (_) {
      if (!mounted) return;

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
      if (mounted) {
        setState(() => _loadingScans = false);
      }
    }
  }

  // ==============================================================
  // LOAD NEAREST VET
  // ==============================================================

  Future<void> _loadNearestVet() async {
    setState(() => _loadingVets = true);

    try {
      final position =
          await LocationService.getCurrentPosition();

      final vets = await ApiClient.instance.getNearbyVets(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _nearestVet = vets.isNotEmpty ? vets.first : null;
        _nearbyVetsCount = vets.length;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _nearestVet = null;
        _nearbyVetsCount = 0;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingVets = false);
      }
    }
  }

  // ==============================================================
  // SELECT DOG
  // ==============================================================

  void _selectDog(Dog dog) {
    setState(() {
      _selectedDog = dog;
    });
  }

  // ==============================================================
  // OPEN SCAN
  // ==============================================================

  Future<void> _openScan(ScanListItem item) async {
    if (item.id.startsWith('demo-')) {
      Navigator.pushNamed(context, '/results');
      return;
    }

    setState(() => _openingScanId = item.id);

    try {
      final full =
          await ApiClient.instance.getScan(item.id);

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/results',
        arguments: full,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _openingScanId = null);
      }
    }
  }

  // ==============================================================
  // START SCAN
  // ==============================================================

  void _startScan() {
    if (_dogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a dog to your profile before starting a scan.',
          ),
        ),
      );

      return;
    }

    if (_selectedDog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a dog first.',
          ),
        ),
      );

      return;
    }

    Navigator.pushNamed(
      context,
      '/analyze',
      arguments: _selectedDog,
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        Supabase.instance.client.auth.currentUser;

    final fullName =
        (user?.userMetadata?['full_name'] as String?)?.trim();

    final displayName =
        (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user?.email ?? 'Pet Parent');

    final firstName =
        displayName.split(RegExp(r'\s+')).first;

    final initials = displayName.trim().isNotEmpty
        ? displayName
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'PC';

    final needsAttention = _scans
        .where(
          (s) =>
              s.severity == 'moderate' ||
              s.severity == 'severe',
        )
        .length;

    final dogName = _selectedDog?.name;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadDogs(),
                    _loadScans(),
                    _loadNearestVet(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GOOD MORNING',
                                style: AppText.eyebrow(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hi, $firstName 👋',
                                style:
                                    AppText.display(size: 20),
                              ),
                            ],
                          ),

                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/profile',
                            ),
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor:
                                  AppColors.accentSoft,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      
                      // ==================================================
                      // SCAN CTA
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(24),
                          gradient:
                              const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEW SCAN',
                              style: AppText.eyebrow(
                                color: AppColors.accent,
                              ),
                            ),

                            const SizedBox(height: 6),

                            SizedBox(
                              width: 240,
                              child: Text(
                                dogName != null
                                    ? "Spotted something on $dogName's fur?"
                                    : "Spotted something on your dog's fur?",
                                style: AppText.display(
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            SizedBox(
                              width: 250,
                              child: Text(
                                'SCANine does not replace veterinary diagnosis. Consult your nearest veterinarian.',
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.accent,
                              ),
                              onPressed:
                                  _dogs.isEmpty
                                      ? () => Navigator
                                          .pushNamed(
                                          context,
                                          '/profile',
                                        )
                                      : _startScan,
                              child: Text(
                                _dogs.isEmpty
                                    ? 'Add a Dog'
                                    : 'Start Scan →',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // STATS
                      // ==================================================

                      Row(
                        children: [
                          _StatBox(
                            num: _loadingScans
                                ? '—'
                                : '${_scans.length}',
                            label: 'Total scans',
                          ),

                          const SizedBox(width: 10),

                          _StatBox(
                            num: _loadingScans
                                ? '—'
                                : '$needsAttention',
                            label: 'Needs attention',
                          ),

                          const SizedBox(width: 10),

                          _StatBox(
                            num: _loadingVets
                                ? '—'
                                : '$_nearbyVetsCount',
                            label: 'Vets nearby',
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // DOG SELECTOR
                      // ==================================================

                      if (!_loadingDogs &&
                          _dogs.isNotEmpty) ...[
                        _SectionTitle(
                          title: 'Scanning for',
                          onSeeAll: () =>
                              Navigator.pushNamed(
                            context,
                            '/profile',
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildDogSelector(),

                        const SizedBox(height: 18),
                      ],


                      // ==================================================
                      // RECENT SCAN
                      // ==================================================

                      _SectionTitle(
                        title: 'Recent scan',
                        onSeeAll: () =>
                            Navigator.pushNamed(
                          context,
                          '/history',
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_usingDemoScans)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: Text(
                            "Showing sample data — couldn't reach the server.",
                            style:
                                AppText.muted(size: 11.5),
                          ),
                        ),

                      if (_loadingScans)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (_scans.isEmpty)
                        Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.line,
                            ),
                          ),
                          child: Text(
                            'No scans yet — start your first one above.',
                            style:
                                AppText.muted(size: 12.5),
                          ),
                        )
                      else
                        _recentScanCard(
                          _scans.first,
                        ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // NEARBY VETS
                      // ==================================================

                      _SectionTitle(
                        title: 'Nearby vets',
                        onSeeAll: () =>
                            Navigator.pushNamed(
                          context,
                          '/vets',
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_loadingVets)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (_nearestVet == null)
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(
                            context,
                            '/vets',
                          ),
                          child: Text(
                            'Enable location to see clinics near you.',
                            style:
                                AppText.muted(size: 12.5),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(
                            context,
                            '/vet-details',
                            arguments:
                                _nearestVet!.placeId,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      AppColors.successSoft,
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '📍',
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nearestVet!.name,
                                      style: AppText.body(
                                        size: 13,
                                        w: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      [
                                        if (_nearestVet!
                                            .distanceLabel
                                            .isNotEmpty)
                                          '${_nearestVet!.distanceLabel} away',
                                        if (_nearestVet!
                                                .openNow !=
                                            null)
                                          _nearestVet!
                                                  .openNow!
                                              ? 'Open now'
                                              : 'Closed',
                                      ].join(' · '),
                                      style:
                                          AppText.muted(
                                        size: 11,
                                      ),
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
            ),

            const PupCheckBottomNav(
              current: 'home',
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // DOG SELECTOR
  // ==============================================================

  Widget _buildDogSelector() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dogs.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dog = _dogs[index];
          final selected =
              _selectedDog?.id == dog.id;

          return GestureDetector(
            onTap: () => _selectDog(dog),
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentSoft
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : AppColors.line,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.accentSoft,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '🐶',
                        style:
                            TextStyle(fontSize: 19),
                      ),
                    ),
                  ),

                  const SizedBox(width: 9),

                  Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        dog.name,
                        style: AppText.body(
                          size: 13,
                          w: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : AppColors.ink,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        dog.subtitle,
                        style:
                            AppText.muted(size: 10),
                      ),
                    ],
                  ),

                  if (selected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==============================================================
  // DOG SUMMARY
  // ==============================================================

  Widget _buildDogSummary() {
    return Container(
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
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '🐶',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDog?.name ?? 'No dog selected',
                  style: AppText.body(
                    size: 14,
                    w: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _selectedDog?.subtitle ??
                      'Select a dog above',
                  style: AppText.muted(size: 11),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(
              context,
              '/profile',
            ),
            child: Text(
              'Manage',
              style: AppText.body(
                size: 12,
                color: AppColors.primary,
                w: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // NO DOGS
  // ==============================================================

  Widget _buildNoDogsCard() {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(
        context,
        '/profile',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your first dog',
                    style: AppText.body(
                      size: 14,
                      w: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Add a dog to start scanning.',
                    style:
                        AppText.muted(size: 11),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // RECENT SCAN CARD
  // ==============================================================

  Widget _recentScanCard(
    ScanListItem item,
  ) {
    final isOpening =
        _openingScanId == item.id;

    return GestureDetector(
      onTap: isOpening
          ? null
          : () => _openScan(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              const Center(
                        child: Text(
                          '🐾',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        '🐾',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.locationLabel ??
                        'Scan',
                    style: AppText.body(
                      size: 13,
                      w: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    DateFormat(
                      'MMM d, h:mm a',
                    ).format(item.createdAt),
                    style:
                        AppText.muted(size: 11),
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

// =================================================================
// STAT BOX
// =================================================================

class _StatBox extends StatelessWidget {
  final String num;
  final String label;

  const _StatBox({
    required this.num,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              num,
              style: AppText.display(
                size: 22,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style:
                  AppText.muted(size: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// SECTION TITLE
// =================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionTitle({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              AppText.display(size: 16),
        ),

        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight:
                    FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}