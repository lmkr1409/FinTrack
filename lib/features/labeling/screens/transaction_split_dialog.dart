import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/transaction.dart';
import '../../../services/providers.dart';

class TransactionSplitDialog extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback onSplitComplete;

  const TransactionSplitDialog({
    super.key,
    required this.transaction,
    required this.onSplitComplete,
  });

  @override
  ConsumerState<TransactionSplitDialog> createState() => _TransactionSplitDialogState();
}

class _TransactionSplitDialogState extends ConsumerState<TransactionSplitDialog> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 splits by default
    final half = widget.transaction.amount / 2;
    _controllers.add(TextEditingController(text: half.toStringAsFixed(2)));
    _controllers.add(TextEditingController(text: (widget.transaction.amount - half).toStringAsFixed(2)));
    _focusNodes.add(FocusNode());
    _focusNodes.add(FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => widget.transaction.amount;

  double get _currentSum {
    double sum = 0;
    for (var c in _controllers) {
      sum += double.tryParse(c.text) ?? 0;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  double get _diff => double.parse((_totalAmount - _currentSum).toStringAsFixed(2));

  void _addSplit() {
    setState(() {
      _controllers.add(TextEditingController(text: '0.00'));
      _focusNodes.add(FocusNode());
    });
  }

  void _removeSplit(int index) {
    if (_controllers.length <= 2) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _focusNodes[index].dispose();
      _focusNodes.removeAt(index);
    });
  }

  Future<void> _executeSplit() async {
    if (_diff != 0) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final originalDesc = widget.transaction.description ?? '';
      
      // Ensure prefix is only added once
      final cleanDesc = originalDesc.startsWith('Split - ') 
          ? originalDesc.replaceFirst('Split - ', '') 
          : originalDesc;

      final subAmounts = _controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();

      // 1. Update the original transaction (T1)
      final firstAmount = subAmounts[0];
      final firstDesc = 'Split - $cleanDesc\nTransaction is split for $firstAmount.';
      
      await repo.updateTransaction(widget.transaction.copyWith(
        amount: firstAmount,
        description: firstDesc,
        updatedTime: nowStr,
      ));

      // 2. Insert new transactions (T2, T3...)
      for (int i = 1; i < subAmounts.length; i++) {
        final amt = subAmounts[i];
        final desc = 'Split - $cleanDesc\nTransaction is split for $amt.';
        
        final newTxn = Transaction(
          transactionType: widget.transaction.transactionType,
          amount: amt,
          transactionDate: widget.transaction.transactionDate,
          description: desc,
          categoryId: widget.transaction.categoryId,
          subcategoryId: widget.transaction.subcategoryId,
          purposeId: widget.transaction.purposeId,
          accountId: widget.transaction.accountId,
          cardId: widget.transaction.cardId,
          merchantId: widget.transaction.merchantId,
          paymentMethodId: widget.transaction.paymentMethodId,
          expenseSourceId: widget.transaction.expenseSourceId,
          relatedTransactionId: widget.transaction.id,
          createdTime: nowStr,
          updatedTime: nowStr,
          nature: widget.transaction.nature,
          goalId: widget.transaction.goalId,
        );
        
        await repo.insertTransaction(newTxn);
      }

      if (mounted) {
        Navigator.pop(context, true); // Close SplitDialog with success result
        widget.onSplitComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split failed: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isValid = _diff == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.call_split_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Split Transaction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total Summary Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${_totalAmount.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Text(
                          _diff == 0 ? 'Balanced' : '₹${_diff.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _diff == 0 ? Colors.green : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable List of Splits
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _controllers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text('${index + 1}', 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                            labelText: 'Amount',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _controllers.length > 2 ? () => _removeSplit(index) : null,
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.expense),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addSplit,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Split'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: (isValid && !_isProcessing) ? _executeSplit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Split Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
