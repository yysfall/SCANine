import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_result.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/pupcheck_bottom_nav.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<ScanListItem> _items = [];
  String? _openingScanId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final items = await ApiClient.instance.listScans();

      setState(() {
        _items = items;
      });
    } catch (_) {
      setState(() {
        _items = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openItem(ScanListItem item) async {
    setState(() => _openingScanId = item.id);

    try {
      final full = await ApiClient.instance.getScan(item.id);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan History',
                        style: AppText.display(size: 20),
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No scans yet',
                              style: AppText.muted(),
                            ),
                          ),
                        )
                      else
                        for (final e in _items)
                          _historyItem(context, e),
                    ],
                  ),
                ),
              ),
            ),
            const PupCheckBottomNav(current: 'history'),
          ],
        ),
      ),
    );
  }

  Widget _historyItem(BuildContext context, ScanListItem e) {
    final isOpening = _openingScanId == e.id;

    return GestureDetector(
      onTap: isOpening ? null : () => _openItem(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: e.imageUrl.isNotEmpty
                  ? Image.network(
                      e.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          '🐾',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        '🐾',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.predictedCondition,
                    style: AppText.body(
                      size: 13,
                      w: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(e.createdAt),
                    style: AppText.muted(size: 11),
                  ),
                ],
              ),
            ),
            if (isOpening)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}