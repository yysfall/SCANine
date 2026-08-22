import 'package:flutter/material.dart';

import '../models/dog.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Opens a bottom sheet to add/edit the dog profile. Returns the saved
/// [Dog] on success so the caller can refresh its display, or null if
/// the sheet was dismissed without saving.
Future<Dog?> showEditDogSheet(BuildContext context, {Dog? current}) {
  return showModalBottomSheet<Dog>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditDogSheet(current: current),
  );
}

class _EditDogSheet extends StatefulWidget {
  final Dog? current;
  const _EditDogSheet({this.current});

  @override
  State<_EditDogSheet> createState() => _EditDogSheetState();
}

class _EditDogSheetState extends State<_EditDogSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.current?.name ?? '');
    _breedCtrl = TextEditingController(text: widget.current?.breed ?? '');
    _ageCtrl = TextEditingController(
      text: widget.current?.ageYears != null ? widget.current!.ageYears!.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Your dog's name is required.");
      return;
    }
    double? age;
    if (_ageCtrl.text.trim().isNotEmpty) {
      age = double.tryParse(_ageCtrl.text.trim());
      if (age == null) {
        setState(() => _error = 'Age should be a number, e.g. 4 or 2.5.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dog = await ApiClient.instance.upsertMyDog(
        name: name,
        breed: _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
        ageYears: age,
      );
      if (!mounted) return;
      Navigator.pop(context, dog);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save right now. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Text(
              widget.current == null ? 'Add your dog' : 'Edit your dog',
              style: AppText.display(size: 18),
            ),
            const SizedBox(height: 18),

            Text('Name', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Bruno')),
            const SizedBox(height: 14),

            Text('Breed (optional)', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _breedCtrl, decoration: const InputDecoration(hintText: 'Golden Retriever')),
            const SizedBox(height: 14),

            Text('Age in years (optional)', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(
              controller: _ageCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '4'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.alert, fontSize: 12)),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
