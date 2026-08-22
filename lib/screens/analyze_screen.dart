import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/scan_submission.dart';
import '../theme/app_theme.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final Set<String> _selectedSymptoms = {};
  bool _uploading = false;

  static const _symptoms = [
    'Itching',
    'Redness',
    'Hair loss',
    'Scaling / flaking',
    'Odor',
    'Swelling',
    'Discharge',
    'Crusting',
    'Bumps / lesions',
  ];

  void _toggle(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _openScan() {
    // Symptoms travel with us so the Scan screen can send them along
    // once a photo is captured there.
    Navigator.pushNamed(context, '/scan', arguments: _selectedSymptoms.toList());
  }

  Future<void> _uploadFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return; // user cancelled

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final args = await submitScan(
        imageBytes: bytes,
        filename: picked.name,
        mimeType: picked.mimeType,
        symptoms: _selectedSymptoms.toList(),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, '/results', arguments: args);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
                            child: const Icon(Icons.arrow_back, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Analyze', style: AppText.display(size: 20)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose how you'd like to check your dog's skin, and tell us what you've noticed.",
                      style: AppText.muted(size: 12.5),
                    ),
                    const SizedBox(height: 20),

                    Text('GET AN IMAGE', style: AppText.eyebrow(color: AppColors.accent)),
                    const SizedBox(height: 10),

                    _OptionCard(
                      icon: Icons.camera_alt_rounded,
                      iconBg: AppColors.accentSoft,
                      iconColor: AppColors.accent,
                      title: 'Scan with Camera',
                      subtitle: 'Live guided scan, best for close-up detail',
                      onTap: _uploading ? null : _openScan,
                    ),
                    const SizedBox(height: 12),
                    _OptionCard(
                      icon: Icons.image_rounded,
                      iconBg: AppColors.successSoft,
                      iconColor: AppColors.success,
                      title: 'Upload a Photo',
                      subtitle: 'Choose an existing image from your gallery',
                      onTap: _uploading ? null : _uploadFromGallery,
                      loading: _uploading,
                    ),

                    const SizedBox(height: 24),
                    Text('SYMPTOMS OBSERVED', style: AppText.eyebrow(color: AppColors.accent)),
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedSymptoms.length} selected · optional, but helps improve accuracy',
                      style: AppText.muted(size: 11.5),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptoms.map((s) => _SymptomChip(
                            label: s,
                            selected: _selectedSymptoms.contains(s),
                            onTap: () => _toggle(s),
                          )).toList(),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _uploading ? null : _openScan,
                        child: const Text('Continue to Scan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PupCheckBottomNav(current: 'analyze'),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body(size: 14, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.muted(size: 11.5)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.arrow_forward, size: 16, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SymptomChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.line, width: 1.5),
        ),
        child: Text(
          selected ? '✓ $label' : label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF0C2649) : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
