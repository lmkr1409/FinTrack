import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/card.dart' as model;
import '../../../services/providers.dart';

/// Bottom sheet for deleting transactions in bulk.
/// Supports: date range, by card, or all transactions.
class DeleteTransactionsSheet extends ConsumerStatefulWidget {
  final VoidCallback onDeleted;

  const DeleteTransactionsSheet({super.key, required this.onDeleted});

  @override
  ConsumerState<DeleteTransactionsSheet> createState() => _DeleteTransactionsSheetState();
}

class _DeleteTransactionsSheetState extends ConsumerState<DeleteTransactionsSheet> {
  int _mode = 0; // 0 = date range, 1 = by card, 2 = all

  String _startDate = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
  String _endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<model.Card> _cards = [];
  int? _selectedCardId;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = DateTime.tryParse(isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStart) {
          _startDate = formatted;
        } else {
          _endDate = formatted;
        }
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    String message;
    switch (_mode) {
      case 0:
        message = 'Delete all transactions between $_startDate and $_endDate?';
        break;
      case 1:
        if (_selectedCardId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a card')));
          return;
        }
        final card = _cards.firstWhere((c) => c.id == _selectedCardId);
        message = 'Delete ALL transactions linked to "${card.cardName}"?';
        break;
      default:
        message = 'Delete ALL transactions? This cannot be undone.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final repo = ref.read(transactionRepositoryProvider);

    int count = 0;
    switch (_mode) {
      case 0:
        count = await repo.deleteByDateRange(_startDate, _endDate);
        break;
      case 1:
        count = await repo.deleteByCardId(_selectedCardId!);
        break;
      default:
        count = await repo.deleteAll();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count transaction(s) deleted.'), backgroundColor: AppColors.expense),
      );
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(children: [
              const Icon(Icons.delete_sweep_rounded, color: AppColors.expense),
              const SizedBox(width: 8),
              const Text('Delete Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            // Mode selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Date Range'), icon: Icon(Icons.date_range_rounded, size: 16)),
                ButtonSegment(value: 1, label: Text('By Card'), icon: Icon(Icons.credit_card_rounded, size: 16)),
                ButtonSegment(value: 2, label: Text('All'), icon: Icon(Icons.delete_forever_rounded, size: 16)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              style: ButtonStyle(
                iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.expense : null),
              ),
            ),
            const SizedBox(height: 20),
            // Mode content
            if (_mode == 0) ...[
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(_startDate),
                    onPressed: () => _pickDate(isStart: true),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→')),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(_endDate),
                    onPressed: () => _pickDate(isStart: false),
                  ),
                ),
              ]),
            ] else if (_mode == 1) ...[
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? const Text('No cards configured.', style: TextStyle(color: AppColors.textMuted))
                      : DropdownButtonFormField<int>(
                          initialValue: _selectedCardId,
                          decoration: const InputDecoration(labelText: 'Select Card', border: OutlineInputBorder()),
                          items: _cards.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.cardName} (${c.cardType})'))).toList(),
                          onChanged: (v) => setState(() => _selectedCardId = v),
                        ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                  SizedBox(width: 8),
                  Expanded(child: Text('This will permanently delete ALL transactions from the database.', style: TextStyle(fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _deleting ? null : _confirmAndDelete,
              icon: _deleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_rounded, size: 18),
              label: Text(_deleting ? 'Deleting…' : 'Delete Transactions'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
