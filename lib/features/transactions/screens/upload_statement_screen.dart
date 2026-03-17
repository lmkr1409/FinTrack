import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/transaction.dart';
import '../../../services/providers.dart';
import '../../../services/statement_parser.dart';
import '../../../services/labeling_rules_service.dart';
import '../../../widgets/glass_card.dart';

/// Screen to upload and import a bank statement file.
class UploadStatementScreen extends ConsumerStatefulWidget {
  const UploadStatementScreen({super.key});

  @override
  ConsumerState<UploadStatementScreen> createState() =>
      _UploadStatementScreenState();
}

class _UploadStatementScreenState extends ConsumerState<UploadStatementScreen> {
  // Lookup data
  List<model.Card> _cards = [];
  List<Account> _accounts = [];
  bool _loadingLookups = true;

  // Form state
  String _selectedBank = 'HDFC Bank';
  int? _selectedCardId;
  bool _overrideExisting = false;
  String? _pickedFilePath;
  String? _pickedFileName;

  // Parse state
  List<ParsedTransaction>? _parsed;
  bool _parsing = false;
  String? _parseError;
  bool _importing = false;

  static const _supportedBanks = ['HDFC Bank', 'SBI', 'SCB'];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    setState(() {
      _cards = cards;
      _accounts = accounts;
      _loadingLookups = false;
    });
  }

  int? get _selectedBankAccountId {
    String mappedName = 'HDFC Bank';
    if (_selectedBank == 'SBI') mappedName = 'State Bank Of India';
    if (_selectedBank == 'SCB') mappedName = 'Standard Chartered Bank';
    
    final acct = _accounts
        .where((a) => a.accountName.toLowerCase() == mappedName.toLowerCase())
        .firstOrNull;
    return acct?.id;
  }

  List<model.Card> get _filteredCards {
    final accountId = _selectedBankAccountId;
    if (accountId == null) return [];
    return _cards.where((c) => c.accountId == accountId).toList();
  }

  /// Derive card type from the selected card for the parser.
  String get _cardTypeForParser {
    if (_selectedCardId == null) return 'debit';
    final card = _cards.where((c) => c.id == _selectedCardId).firstOrNull;
    if (card == null) return 'debit';
    return card.cardType.toLowerCase();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
        _parsed = null;
        _parseError = null;
      });
      await _parseFile();
    }
  }

  Future<void> _parseFile() async {
    if (_pickedFilePath == null) return;
    setState(() {
      _parsing = true;
      _parseError = null;
    });
    try {
      final parsed = await StatementParser.parse(
        filePath: _pickedFilePath!,
        bank: _selectedBank,
        cardType: _cardTypeForParser,
      );
      setState(() {
        _parsed = parsed;
        _parsing = false;
      });
    } catch (e) {
      setState(() {
        _parseError = e.toString();
        _parsing = false;
      });
    }
  }

  Future<void> _import() async {
    if (_parsed == null || _parsed!.isEmpty) return;
    setState(() => _importing = true);

    try {
      final txnRepo = ref.read(transactionRepositoryProvider);

      // Find BANK_STATEMENT expense source
      final sourceRepo = ref.read(expenseSourceRepositoryProvider);
      final sources = await sourceRepo.getAllSorted();
      final bankStatementSource = sources
          .where((s) => s.expenseSourceName.toUpperCase() == 'BANK_STATEMENT')
          .firstOrNull;

      // Load all accounts to match parsed string names
      final accountRepo = ref.read(accountRepositoryProvider);
      final accounts = await accountRepo.getAllSorted();

      // Load labeling rules
      final rulesRepo = ref.read(labelingRuleRepositoryProvider);
      final labelingRules = await rulesRepo.getAllSorted();

      // Determine default accountId from the selected card
      int? defaultAccountId;
      if (_selectedCardId != null) {
        final card = _cards.where((c) => c.id == _selectedCardId).firstOrNull;
        defaultAccountId = card?.accountId;
      }

      // Override: delete existing transactions in the date range for this account/card
      if (_overrideExisting && _parsed!.isNotEmpty) {
        final dates = _parsed!.map((t) => t.date).toList()..sort();
        await txnRepo.deleteByDateRangeAndAccount(
          startDate: dates.first,
          endDate: dates.last,
          accountId: defaultAccountId,
          cardId: _selectedCardId,
        );
      }

      // Build transaction objects
      final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final transactions = _parsed!.map((p) {
        // Convert Credit Card payments (Credits) into Transfers so they aren't marked as Income
        String type = p.transactionType;
        if (type == 'CREDIT') {
          if (_cardTypeForParser == 'credit') {
             // For credit card statements, incoming money (CREDIT) is typically a payment -> TRANSFER
             type = 'TRANSFER';
          } else {
             // For debit/account statements, money in is typically Income (CREDIT).
             // Let's explicitly check if it's a credit card payment from the account, or self transfer,
             // and if not, leave it as CREDIT (Income).
             final descLower = p.description.toLowerCase();
             if (descLower.contains('cr card') || descLower.contains('credit card') || 
                 descLower.contains('to own a/c') || descLower.contains('to own account')) {
               type = 'TRANSFER';
             }
          }
        }

        // Try to map parsed Card Name
        int? rowCardId = _selectedCardId;
        if (p.cardName != null) {
          final matchedCard = _cards
              .where(
                (c) => c.cardName.toLowerCase() == p.cardName!.toLowerCase(),
              )
              .firstOrNull;
          if (matchedCard != null) rowCardId = matchedCard.id;
        }

        // Try to map parsed Account Name
        int? rowAccountId = defaultAccountId;
        if (p.accountName != null) {
          final matchedAcct = accounts
              .where(
                (a) =>
                    a.accountName.toLowerCase() == p.accountName!.toLowerCase(),
              )
              .firstOrNull;
          if (matchedAcct != null) {
            rowAccountId = matchedAcct.id;
          }
        }

        final txn = Transaction(
          transactionType: type,
          amount: p.amount,
          transactionDate: p.date,
          description: p.description,
          accountId: rowAccountId,
          cardId: rowCardId,
          expenseSourceId: bankStatementSource?.id,
          createdTime: now,
          updatedTime: now,
          labeled: false,
        );
        return LabelingRulesService.applyRules(txn, labelingRules);
      }).toList();

      await txnRepo.insertBatch(transactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transactions.length} transactions imported!'),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLookups) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upload Statement')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Statement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Bank ───────────────────────────────────
          DropdownButtonFormField<String>(
            key: ValueKey('bank_$_selectedBank'),
            initialValue: _selectedBank,
            decoration: const InputDecoration(
              labelText: 'Bank',
              border: OutlineInputBorder(),
            ),
            items: _supportedBanks
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedBank = v!;
              _selectedCardId = null; // Reset card selection when bank changes
              _parsed = null;
            }),
          ),
          const SizedBox(height: 12),

          // ─── Card ───────────────────────────────────
          DropdownButtonFormField<int?>(
            key: ValueKey('card_$_selectedCardId'),
            initialValue: (_selectedCardId != null && _filteredCards.any((c) => c.id == _selectedCardId)) 
                ? _selectedCardId 
                : null,
            decoration: const InputDecoration(
              labelText: 'Card',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._filteredCards.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.cardName)),
              ),
            ],
            onChanged: (v) => setState(() {
              _selectedCardId = v;
              _parsed = null;
            }),
          ),
          const SizedBox(height: 12),

          // ─── Override ────────────────────────────────
          SwitchListTile(
            title: const Text('Override existing transactions'),
            subtitle: const Text(
              'Deletes transactions in the same date range for selected card',
            ),
            value: _overrideExisting,
            onChanged: (v) => setState(() => _overrideExisting = v),
            activeTrackColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),

          // ─── File Picker ────────────────────────────
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_pickedFileName ?? 'Pick Statement File (CSV / XLSX)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Parse Status ───────────────────────────
          if (_parsing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),

          if (_parseError != null)
            GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.expense.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.expense),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: TextStyle(color: AppColors.expense, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Preview ────────────────────────────────
          if (_parsed != null && !_parsing) _buildPreview(),

          const SizedBox(height: 16),

          // ─── Import ─────────────────────────────────
          if (_parsed != null && _parsed!.isNotEmpty && !_parsing)
            FilledButton.icon(
              onPressed: _importing ? null : _import,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_done_rounded),
              label: Text(
                _importing
                    ? 'Importing...'
                    : 'Import ${_parsed!.length} Transactions',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final parsed = _parsed!;
    final totalDebit = parsed
        .where((t) => t.isDebit)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalCredit = parsed
        .where((t) => !t.isDebit)
        .fold<double>(0, (s, t) => s + t.amount);
    final debitCount = parsed.where((t) => t.isDebit).length;
    final creditCount = parsed.where((t) => !t.isDebit).length;
    final dates = parsed.map((t) => t.date).toList()..sort();

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statement Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Transactions found', '${parsed.length}'),
          if (dates.isNotEmpty)
            _infoRow('Date range', '${dates.first} → ${dates.last}'),
          _infoRow(
            'Debits',
            '$debitCount • ₹${totalDebit.toStringAsFixed(2)}',
            color: AppColors.expense,
          ),
          _infoRow(
            'Credits',
            '$creditCount • ₹${totalCredit.toStringAsFixed(2)}',
            color: AppColors.income,
          ),
          const Divider(height: 20),
          // Show first 5 rows
          ...parsed
              .take(5)
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          t.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${t.isDebit ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.isDebit
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (parsed.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... and ${parsed.length - 5} more',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
