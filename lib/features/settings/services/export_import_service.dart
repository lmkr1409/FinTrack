import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';

import '../../../repositories/account_repository.dart';
import '../../../repositories/base_repository.dart';
import '../../../repositories/budget_repository.dart';
import '../../../repositories/card_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/expense_purpose_repository.dart';
import '../../../repositories/expense_source_repository.dart';
import '../../../repositories/merchant_repository.dart';
import '../../../repositories/payment_method_repository.dart';
import '../../../repositories/sub_category_repository.dart';
import '../../../repositories/transaction_repository.dart';
import '../../../repositories/budget_total_repository.dart';
import '../../../repositories/merchant_rule_repository.dart';
import '../../../repositories/transaction_rule_repository.dart';

import '../../../models/account.dart';
import '../../../models/budget.dart';
import '../../../models/card.dart' as f_card;
import '../../../models/category.dart' as f_cat;
import '../../../models/expense_purpose.dart';
import '../../../models/expense_source.dart';
import '../../../models/merchant.dart';
import '../../../models/payment_method.dart';
import '../../../models/sub_category.dart';
import '../../../models/transaction.dart' as f_txn;

final exportImportServiceProvider = Provider((ref) {
  return ExportImportService();
});

class ExportImportService {
  final _accountRepo = AccountRepository();
  final _cardRepo = CardRepository();
  final _categoryRepo = CategoryRepository();
  final _subCategoryRepo = SubCategoryRepository();
  final _expensePurposeRepo = ExpensePurposeRepository();
  final _expenseSourceRepo = ExpenseSourceRepository();
  final _merchantRepo = MerchantRepository();
  final _paymentMethodRepo = PaymentMethodRepository();
  final _budgetRepo = BudgetRepository();
  final _transactionRepo = TransactionRepository();
  final _budgetTotalRepo = BudgetTotalRepository();
  final _merchantRuleRepo = MerchantRuleRepository();
  final _transactionRuleRepo = TransactionRuleRepository();

  /// EXPORT FUNCTIONALITY
  Future<String?> exportData({
    required bool exportConfig,
    required bool exportTransactions,
    int? filterAccountId,
    int? filterCardId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> exportMap = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (exportConfig) {
        exportMap['configuration'] = await _exportConfiguration();
      }

      if (exportTransactions) {
        exportMap['transactions'] = await _exportTransactions(
          accountId: filterAccountId,
          cardId: filterCardId,
          startDate: startDate,
          endDate: endDate,
        );
      }

      final jsonString = jsonEncode(exportMap);
      final bytes = utf8.encode(jsonString);

      final String fileName = 'FinTrack_Backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      // Use file picker to save file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (outputFile == null) return null; // User canceled

      // Optional: If outputFile is provided and file_picker didn't write it automatically
      // try writing it (more relevant for desktop, on Android file_picker handles bytes if provided)
      try {
        final file = File(outputFile);
        if (!await file.exists()) {
           await file.writeAsBytes(bytes);
        }
      } catch (_) {}

      return outputFile;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Saves the raw SQLite database file as a .db file using FilePicker.
  Future<String?> downloadDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, AppConstants.databaseName);
      final file = File(path);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final String fileName = AppConstants.databaseName;

        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Database File',
          fileName: fileName,
          type: FileType.any,
          bytes: bytes,
        );

        if (outputFile == null) return null;

        try {
          final outFile = File(outputFile);
          if (!await outFile.exists()) {
            await outFile.writeAsBytes(bytes);
          }
        } catch (_) {}

        return outputFile;
      } else {
        throw Exception('Database file not found at $path');
      }
    } catch (e) {
      throw Exception('Failed to download database: $e');
    }
  }

  Future<Map<String, dynamic>> _exportConfiguration() async {
    return {
      'accounts': (await _accountRepo.getAll()).map((e) => e.toMap()).toList(),
      'cards': (await _cardRepo.getAll()).map((e) => e.toMap()).toList(),
      'categories': (await _categoryRepo.getAll()).map((e) => e.toMap()).toList(),
      'sub_categories': (await _subCategoryRepo.getAll()).map((e) => e.toMap()).toList(),
      'expense_purposes': (await _expensePurposeRepo.getAll()).map((e) => e.toMap()).toList(),
      'expense_sources': (await _expenseSourceRepo.getAll()).map((e) => e.toMap()).toList(),
      'merchants': (await _merchantRepo.getAll()).map((e) => e.toMap()).toList(),
      'payment_methods': (await _paymentMethodRepo.getAll()).map((e) => e.toMap()).toList(),
      'budgets': (await _budgetRepo.getAll()).map((e) => e.toMap()).toList(),
      'budget_totals': (await _budgetTotalRepo.getAll()).map((e) => e.toMap()).toList(),
      'merchant_rules': (await _merchantRuleRepo.getAll()).map((e) => e.toMap()).toList(),
      'transaction_rules': (await _transactionRuleRepo.getAll()).map((e) => e.toMap()).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> _exportTransactions({
    int? accountId,
    int? cardId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereStr = '1=1';
    List<dynamic> whereArgs = [];

    if (accountId != null) {
      whereStr += ' AND account_id = ?';
      whereArgs.add(accountId);
    }
    if (cardId != null) {
      whereStr += ' AND card_id = ?';
      whereArgs.add(cardId);
    }
    if (startDate != null) {
        whereStr += ' AND transaction_date >= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(startDate));
    }
    if (endDate != null) {
        whereStr += ' AND transaction_date <= ?';
        whereArgs.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    final List<f_txn.Transaction> txns = await _transactionRepo.query(
      where: whereStr,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return txns.map((t) => t.toMap()).toList();
  }

  /// IMPORT FUNCTIONALITY
  Future<void> importData({required bool importConfig, required bool importTransactions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> importMap = jsonDecode(jsonString);

      if (importMap['version'] > 2) {
        throw Exception('Unsupported backup version.');
      }

      Map<String, Map<int, int>> idMaps = {
        'accounts': {},
        'categories': {},
        'sub_categories': {},
        'expense_purposes': {},
        'expense_sources': {},
        'merchants': {},
        'payment_methods': {},
        'cards': {},
        'merchant_rules': {},
        'transaction_rules': {},
      };

      if (importConfig && importMap.containsKey('configuration')) {
        await _importConfiguration(importMap['configuration'], idMaps);
      }

      if (importTransactions && importMap.containsKey('transactions')) {
        await _importTransactions(importMap['transactions'], idMaps);
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  Future<void> _importConfiguration(Map<String, dynamic> config, Map<String, Map<int, int>> idMaps) async {
    // 1. Independent Entities FIRST (No Foreign Keys)
    idMaps['categories'] = await _mapAndInsert<f_cat.Category>(
      data: config['categories'] ?? [],
      repo: _categoryRepo,
      uniqueField: 'category_name',
      idField: 'category_id',
    );

    idMaps['accounts'] = await _mapAndInsert<Account>(
      data: config['accounts'] ?? [],
      repo: _accountRepo,
      uniqueField: 'account_name',
      idField: 'account_id',
    );

    idMaps['merchants'] = await _mapAndInsert<Merchant>(
      data: config['merchants'] ?? [],
      repo: _merchantRepo,
      uniqueField: 'merchant_name',
      idField: 'merchant_id',
    );

    idMaps['payment_methods'] = await _mapAndInsert<PaymentMethod>(
      data: config['payment_methods'] ?? [],
      repo: _paymentMethodRepo,
      uniqueField: 'payment_method_name',
      idField: 'payment_method_id',
    );

    idMaps['expense_purposes'] = await _mapAndInsert<ExpensePurpose>(
      data: config['expense_purposes'] ?? [],
      repo: _expensePurposeRepo,
      uniqueField: 'expense_for',
      idField: 'purpose_id',
    );

    idMaps['expense_sources'] = await _mapAndInsert<ExpenseSource>(
      data: config['expense_sources'] ?? [],
      repo: _expenseSourceRepo,
      uniqueField: 'expense_source_name',
      idField: 'expense_source_id',
    );

    // 2. Dependent Entities SECOND (Requires Foreign Keys)
    
    // Cards require account_id
    idMaps['cards'] = await _mapAndInsertDependent<f_card.Card>(
      data: config['cards'] ?? [],
      repo: _cardRepo,
      uniqueField: 'card_number',
      idField: 'card_id',
      fkMappings: [
        MapEntry('account_id', idMaps['accounts']!),
      ]
    );

    // SubCategories require category_id
    idMaps['sub_categories'] = await _mapAndInsertDependent<SubCategory>(
      data: config['sub_categories'] ?? [],
      repo: _subCategoryRepo,
      uniqueField: 'subcategory_name',
      idField: 'subcategory_id',
      fkMappings: [
        MapEntry('category_id', idMaps['categories']!),
      ]
    );

    // Budgets require category_id
    await _mapAndInsertDependent<Budget>(
      data: config['budgets'] ?? [],
      repo: _budgetRepo,
      uniqueField: null, // Always insert new budgets
      idField: 'budget_id',
      fkMappings: [
        MapEntry('category_id', idMaps['categories']!),
      ]
    );

    // 3. New Entities for Version 2
    
    // Budget Totals (Independent)
    await _mapAndInsert<f_txn.Transaction>( // I'll use a dummy type or just rely on the map behavior
        data: config['budget_totals'] ?? [],
        repo: _budgetTotalRepo,
        uniqueField: null,
        idField: 'total_id',
    );

    // Merchant Rules (Dependent on merchants, categories, sub_categories, purposes)
    idMaps['merchant_rules'] = await _mapAndInsertDependent<f_txn.Transaction>(
      data: config['merchant_rules'] ?? [],
      repo: _merchantRuleRepo,
      uniqueField: 'keyword',
      idField: 'rule_id',
      fkMappings: [
        MapEntry('merchant_id', idMaps['merchants']!),
        MapEntry('category_id', idMaps['categories']!),
        MapEntry('subcategory_id', idMaps['sub_categories']!),
        MapEntry('purpose_id', idMaps['expense_purposes']!),
      ]
    );

    // Transaction Rules (Dependent on accounts, cards, payment methods)
    idMaps['transaction_rules'] = await _mapAndInsertDependent<f_txn.Transaction>(
      data: config['transaction_rules'] ?? [],
      repo: _transactionRuleRepo,
      uniqueField: null, // Multiple patterns for same type/id might exist or we use a custom check
      idField: 'rule_id',
      fkMappings: [
        MapEntry('account_id', idMaps['accounts']!),
        MapEntry('card_id', idMaps['cards']!),
        MapEntry('payment_method_id', idMaps['payment_methods']!),
      ]
    );
  }

  Future<void> _importTransactions(List<dynamic> txnsData, Map<String, Map<int, int>> idMaps) async {
    for (var item in txnsData) {
      Map<String, dynamic> txnMap = Map<String, dynamic>.from(item);
      
      // Remove old primary key to let SQLite generate a new one
      txnMap.remove('transaction_id');

      // Map Foreign Keys
      if (txnMap['account_id'] != null) {
        txnMap['account_id'] = idMaps['accounts']?[txnMap['account_id']] ?? txnMap['account_id'];
      }
      if (txnMap['card_id'] != null) {
        txnMap['card_id'] = idMaps['cards']?[txnMap['card_id']] ?? txnMap['card_id'];
      }
      if (txnMap['category_id'] != null) {
        txnMap['category_id'] = idMaps['categories']?[txnMap['category_id']] ?? txnMap['category_id'];
      }
      if (txnMap['subcategory_id'] != null) {
        txnMap['subcategory_id'] = idMaps['sub_categories']?[txnMap['subcategory_id']] ?? txnMap['subcategory_id'];
      }
      if (txnMap['purpose_id'] != null) {
        txnMap['purpose_id'] = idMaps['expense_purposes']?[txnMap['purpose_id']] ?? txnMap['purpose_id'];
      }
      if (txnMap['merchant_id'] != null) {
        txnMap['merchant_id'] = idMaps['merchants']?[txnMap['merchant_id']] ?? txnMap['merchant_id'];
      }
      if (txnMap['payment_method_id'] != null) {
        txnMap['payment_method_id'] = idMaps['payment_methods']?[txnMap['payment_method_id']] ?? txnMap['payment_method_id'];
      }
      if (txnMap['expense_source_id'] != null) {
        txnMap['expense_source_id'] = idMaps['expense_sources']?[txnMap['expense_source_id']] ?? txnMap['expense_source_id'];
      }

      await _transactionRepo.insert(txnMap);
    }
  }

  /// Helper to insert independent entities and return an ID map (Old -> New)
  Future<Map<int, int>> _mapAndInsert<T>({
    required List<dynamic> data,
    required BaseRepository repo,
    required String? uniqueField,
    required String idField,
  }) async {
    Map<int, int> idMap = {};
    for (var item in data) {
      final mapItem = Map<String, dynamic>.from(item);
      int oldId = mapItem[idField];
      int newId;

      if (uniqueField != null) {
        // Check if item exists
        final existing = await repo.query(
          where: '$uniqueField = ?',
          whereArgs: [mapItem[uniqueField]],
        );

        if (existing.isNotEmpty) {
           // Item exists, map to existing ID
           // Because we use type parameters and generic repositories, we need to extract the MAP of the result or just use the known map item manually
           // To be safe, let's query raw to get the map explicitly
          final rawExisting = await repo.rawQuery('SELECT * FROM ${repo.tableName} WHERE $uniqueField = ? LIMIT 1', [mapItem[uniqueField]]);
           if(rawExisting.isNotEmpty) {
             newId = rawExisting.first[idField] as int;
             idMap[oldId] = newId;
             continue; // Skip insertion
           }
        }
      }

      // Prepare for insertion
      mapItem.remove(idField);
      newId = await repo.insert(mapItem);
      idMap[oldId] = newId;
    }
    return idMap;
  }

  /// Helper for dependent entities requiring Foreign Key Replacement before insertion
  Future<Map<int, int>> _mapAndInsertDependent<T>({
    required List<dynamic> data,
    required BaseRepository repo,
    required String? uniqueField,
    required String idField,
    required List<MapEntry<String, Map<int,int>>> fkMappings,
  }) async {
     Map<int, int> idMap = {};
    for (var item in data) {
      final mapItem = Map<String, dynamic>.from(item);
      int oldId = mapItem[idField];
      int newId;

      // Swap Foreign Keys
      for(var fk in fkMappings) {
        String fkCol = fk.key;
        Map<int,int> mapDict = fk.value;
        if(mapItem[fkCol] != null && mapDict.containsKey(mapItem[fkCol])) {
           mapItem[fkCol] = mapDict[mapItem[fkCol]];
        }
      }

       if (uniqueField != null) {
        // Check if item exists
        final existing = await repo.rawQuery('SELECT * FROM ${repo.tableName} WHERE $uniqueField = ? LIMIT 1', [mapItem[uniqueField]]);
        if(existing.isNotEmpty) {
            newId = existing.first[idField] as int;
            idMap[oldId] = newId;
            continue; // Skip insertion
        }
      }

      // Prepare for insertion
      mapItem.remove(idField);
      newId = await repo.insert(mapItem);
      idMap[oldId] = newId;
    }
    return idMap;
  }
}
