import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dog.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/edit_dog_sheet.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadingDogs = true;
  List<Dog> _dogs = [];

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() => _loadingDogs = true);

    try {
      final dogs = await ApiClient.instance.getDogs();

      if (!mounted) return;

      setState(() {
        _dogs = dogs;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dogs = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load your dogs: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingDogs = false);
      }
    }
  }

  Future<void> _addDog() async {
    final saved = await showEditDogSheet(
      context,
      current: null,
    );

    if (saved != null) {
      await _loadDogs();
    }
  }

  Future<void> _editDog(Dog dog) async {
    final saved = await showEditDogSheet(
      context,
      current: dog,
    );

    if (saved != null) {
      await _loadDogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final fullName =
        (user?.userMetadata?['full_name'] as String?)?.trim();

    final displayName =
        (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user?.email ?? 'Pet Parent');

    final email = user?.email ?? '';

    final initials = displayName.trim().isNotEmpty
        ? displayName
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'PC';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDogs,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      // ------------------------------------------------
                      // PROFILE HEADER
                      // ------------------------------------------------

                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            CircleAvatar(
                              radius: 39,
                              backgroundColor:
                                  AppColors.primary,
                              child: Text(
                                initials,
                                style: AppText.display(
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              displayName,
                              style: AppText.display(size: 17),
                            ),

                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: AppText.muted(size: 12),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // MY DOGS
                      // ------------------------------------------------

                      Text(
                        'MY DOGS',
                        style: AppText.eyebrow(
                          color: AppColors.accent,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_loadingDogs)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (_dogs.isEmpty)
                        _buildEmptyDogCard()
                      else
                        Column(
                          children: [
                            ..._dogs.map(
                              (dog) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 10,
                                ),
                                child: _buildDogCard(dog),
                              ),
                            ),

                            const SizedBox(height: 2),

                            _buildAddDogButton(),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // LOG OUT
                      // ------------------------------------------------

                      GestureDetector(
                        onTap: () async {
                          await Supabase.instance.client.auth
                              .signOut();

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (r) => false,
                            );
                          }
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.alertSoft,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  size: 16,
                                  color: AppColors.alert,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Text(
                                'Log out',
                                style: TextStyle(
                                  color: AppColors.alert,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const PupCheckBottomNav(
              current: 'profile',
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // DOG CARD
  // ==============================================================

  Widget _buildDogCard(Dog dog) {
    return GestureDetector(
      onTap: () => _editDog(dog),
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
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
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
                    dog.name,
                    style: AppText.body(
                      size: 14,
                      w: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    dog.subtitle,
                    style: AppText.muted(size: 11),
                  ),
                ],
              ),
            ),

            Text(
              'Edit',
              style: AppText.body(
                size: 12,
                color: AppColors.primary,
                w: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // ADD DOG BUTTON
  // ==============================================================

  Widget _buildAddDogButton() {
    return InkWell(
      onTap: _addDog,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.line,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 18,
              color: AppColors.accent,
            ),

            const SizedBox(width: 6),

            Text(
              'Add another dog',
              style: AppText.body(
                size: 13,
                color: AppColors.accent,
                w: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyDogCard() {
    return GestureDetector(
      onTap: _addDog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
                borderRadius: BorderRadius.circular(12),
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
                    'Add your dog to start using PupCheck.',
                    style: AppText.muted(size: 11),
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