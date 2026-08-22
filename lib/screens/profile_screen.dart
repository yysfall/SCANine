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
  bool _loadingDog = true;
  Dog? _dog;

  @override
  void initState() {
    super.initState();
    _loadDog();
  }

  Future<void> _loadDog() async {
    setState(() => _loadingDog = true);
    try {
      final dog = await ApiClient.instance.getMyDog();
      setState(() => _dog = dog);
    } catch (_) {
      // Leave _dog null — card shows an "Add your dog" state.
    } finally {
      if (mounted) setState(() => _loadingDog = false);
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
    final email = user?.email ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : 'PC';

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
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          CircleAvatar(
                            radius: 39,
                            backgroundColor: AppColors.primary,
                            child: Text(initials, style: AppText.display(size: 26, color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          Text(displayName, style: AppText.display(size: 17)),
                          if (email.isNotEmpty) Text(email, style: AppText.muted(size: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('MY DOG', style: AppText.eyebrow(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    _loadingDog
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : GestureDetector(
                            onTap: _editDog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
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
                    
                    GestureDetector(
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(color: AppColors.alertSoft, borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.logout, size: 16, color: AppColors.alert),
                            ),
                            const SizedBox(width: 12),
                            Text('Log out', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PupCheckBottomNav(current: 'profile'),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppText.body(size: 14, w: FontWeight.w600)),
        ],
      ),
    );
  }
}
