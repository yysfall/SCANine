import 'package:flutter/material.dart';

import '../models/dog.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Result of the edit-dog sheet: either a dog was created/updated
/// ([saved] set), or an existing dog was deleted ([deletedId] set), or
/// the sheet was dismissed with neither set (both null) — check which
/// one is non-null to know what happened.
class EditDogResult {
  final Dog? saved;
  final String? deletedId;

  EditDogResult.saved(Dog dog)
      : saved = dog,
        deletedId = null;

  EditDogResult.deleted(String dogId)
      : saved = null,
        deletedId = dogId;
}

/// Opens a bottom sheet to add a new dog, or edit/delete an existing one
/// when [current] is provided.
Future<EditDogResult?> showEditDogSheet(BuildContext context, {Dog? current}) {
  return showModalBottomSheet<EditDogResult>(
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
  bool _deleting = false;
  String? _error;

  bool get _isEditing => widget.current != null;

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
      final breed = _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim();
      final dog = _isEditing
          ? await ApiClient.instance.updateDog(widget.current!.id, name: name, breed: breed, ageYears: age)
          : await ApiClient.instance.createDog(name: name, breed: breed, ageYears: age);
      if (!mounted) return;
      Navigator.pop(context, EditDogResult.saved(dog));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save right now. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${widget.current!.name}?'),
        content: const Text('This removes their profile. Past scans are kept, just no longer linked to a dog card.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ApiClient.instance.deleteDog(widget.current!.id);
      if (!mounted) return;
      Navigator.pop(context, EditDogResult.deleted(widget.current!.id));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not delete right now. Please try again.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

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
              _isEditing ? 'Edit ${widget.current!.name}' : 'Add a dog',
              style: AppText.display(size: 18),
            ),
            const SizedBox(height: 18),

            Text('Name', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _nameCtrl, decoration:  InputDecoration(hintText: 'Type your dog''s name',hintStyle: AppText.body(
                    size: 13,
                    w: FontWeight.w400,
                    color: AppColors.inkSoft,
                  ),)),
            const SizedBox(height: 14),

            Text('Breed (optional)', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(controller: _breedCtrl, decoration: InputDecoration(hintText: 'Type your dog''s breed',hintStyle: AppText.body(
                    size: 13,
                    w: FontWeight.w400,
                    color: AppColors.inkSoft,
                  ),)),
            const SizedBox(height: 14),

            Text('Age in years (optional)', style: AppText.body(size: 12, w: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(
              controller: _ageCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: 'Type your dog''s age in years',hintStyle: AppText.body(
                    size: 13,
                    w: FontWeight.w400,
                    color: AppColors.inkSoft,
                  ),),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.alert, fontSize: 12)),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Dog'),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: busy ? null : _confirmDelete,
                  child: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Delete This Dog', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}