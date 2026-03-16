import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

/// A single parsed row from a bank statement.
class ParsedTransaction {
  final String date;       // yyyy-MM-dd
  final String description;
  final double? debitAmount;
  final double? creditAmount;
  final String? accountName;
  final String? cardName;

  const ParsedTransaction({
    required this.date,
    required this.description,
    this.debitAmount,
    this.creditAmount,
    this.accountName,
    this.cardName,
  });

  /// Whether this is a debit transaction.
  bool get isDebit => debitAmount != null && debitAmount! > 0;

  /// The absolute amount.
  double get amount => (isDebit ? debitAmount : creditAmount) ?? 0;

  /// DEBIT or CREDIT.
  String get transactionType => isDebit ? 'DEBIT' : 'CREDIT';
}

/// Parses bank statement files (CSV / XLSX / tilde-delimited).
/// Dart port of Django `ParseStatements` class.
class StatementParser {
  /// Entry point — determine bank + card type and delegate.
  static Future<List<ParsedTransaction>> parse({
    required String filePath,
    required String bank,
    required String cardType,
  }) async {
    final ext = filePath.split('.').last.toLowerCase();
    final bankUpper = bank.toUpperCase();

    if (bankUpper == 'HDFC BANK' || bankUpper == 'HDFC') {
      if (cardType.toLowerCase() == 'credit') {
        return _parseHdfcCreditCard(filePath, ext);
      }
      return _parseHdfcAccount(filePath, ext);
    }

    // Fallback: generic CSV with headers Date, Description/Narration, Debit/Withdrawal, Credit/Deposit
    if (ext == 'csv') {
      return _parseGenericCsv(filePath);
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _parseGenericExcel(filePath);
    }
    throw Exception('Unsupported file format: $ext');
  }

  // ─── HDFC Account Statement (CSV / XLSX) ────────────────

  static Future<List<ParsedTransaction>> _parseHdfcAccount(String filePath, String ext) async {
    List<List<dynamic>> rows;
    if (ext == 'csv') {
      rows = _readCsvFile(filePath);
    } else if (ext == 'xlsx' || ext == 'xls') {
      rows = _readExcelFile(filePath);
    } else {
      throw Exception('Supported formats: csv, xlsx, xls');
    }

    // Find the header row by dynamically searching for "Date" and "Narration" anywhere in the row
    int headerIdx = -1;
    int dateIdx = -1;
    int narrationIdx = -1;
    int withdrawalIdx = -1;
    int depositIdx = -1;

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i].map((e) => e.toString().trim().toLowerCase()).toList();
      
      if (r.contains('date') && r.contains('narration') && 
         (r.contains('withdrawal amt.') || r.contains('withdrawal amt') || r.contains('deposit amt.') || r.contains('deposit amt'))) {
        headerIdx = i;
        dateIdx = r.indexOf('date');
        narrationIdx = r.indexOf('narration');
        withdrawalIdx = r.indexWhere((h) => h == 'withdrawal amt.' || h == 'withdrawal amt');
        depositIdx = r.indexWhere((h) => h == 'deposit amt.' || h == 'deposit amt');
        break;
      }
    }
    
    if (headerIdx == -1) throw Exception('Could not find HDFC header row (Date, Narration, Withdrawal/Deposit)');
    if (withdrawalIdx == -1 && depositIdx == -1) {
      throw Exception('Could not find Withdrawal or Deposit columns in HDFC statement');
    }

    final results = <ParsedTransaction>[];
    
    final maxIdx = [dateIdx, narrationIdx, withdrawalIdx, depositIdx].reduce((a, b) => a > b ? a : b);

    for (int i = headerIdx + 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.isEmpty || r.length <= maxIdx || r[dateIdx].toString().trim().isEmpty) continue;

      final rawDate = r[dateIdx].toString().trim();
      final date = _parseDate(rawDate);
      
      // Mimicking pandas `errors="coerce"`. If a row fails to form a date (e.g. asterisks), just log/skip it, don't break the whole loop
      if (date == null) continue;

      final description = r[narrationIdx].toString().trim();
      final debit = _parseAmount(r[withdrawalIdx].toString());
      final credit = _parseAmount(r[depositIdx].toString());

      if ((debit != null && debit > 0) || (credit != null && credit > 0)) {
        results.add(ParsedTransaction(date: date, description: description, debitAmount: debit, creditAmount: credit));
      }
    }
    return results;
  }

  // ─── HDFC Credit Card Statement (tilde-delimited) ───────

  static Future<List<ParsedTransaction>> _parseHdfcCreditCard(String filePath, String ext) async {
    final results = <ParsedTransaction>[];

    if (ext == 'csv' || ext == 'xlsx' || ext == 'xls') {
      List<List<dynamic>> rows;
      if (ext == 'csv') {
        rows = _readCsvFile(filePath);
      } else {
        rows = _readExcelFile(filePath);
      }

      int headerIdx = -1;
      for (int i = 0; i < rows.length && i < 20; i++) {
        final r = rows[i].map((e) => e.toString().trim().toLowerCase()).toList();
        if (r.contains('date') && (r.contains('transaction description') || r.contains('reward points'))) {
          headerIdx = i;
          break;
        }
      }

      if (headerIdx != -1) {
        final headers = rows[headerIdx].map((e) => e.toString().trim().toLowerCase()).toList();
        final dateIdx = headers.indexOf('date');
        final descIdx = headers.indexOf('transaction description');
        final amountIdx = headers.indexOf('amount');
        final crDrIdx = headers.indexOf('cr/dr');

        if (dateIdx != -1 && descIdx != -1 && amountIdx != -1 && crDrIdx != -1) {
          for (int i = headerIdx + 1; i < rows.length; i++) {
            final r = rows[i];
            if (r.isEmpty || r.length <= dateIdx || r[dateIdx].toString().trim().isEmpty) continue;

            final rawDate = r[dateIdx].toString().trim();
            final date = _parseDate(rawDate);
            if (date == null) continue;

            final description = r[descIdx].toString().trim();
            final amountStr = r[amountIdx].toString().trim();
            final crDr = r[crDrIdx].toString().trim();

            final amount = _parseAmount(amountStr);
            if (amount == null || amount <= 0) continue;

            results.add(ParsedTransaction(
              date: date,
              description: description,
              debitAmount: crDr.toUpperCase() != 'CR' ? amount : null,
              creditAmount: crDr.toUpperCase() == 'CR' ? amount : null,
            ));
          }
          if (results.isNotEmpty) return results;
        }
      }
    }

    // Fallback parsing (tilde-delimited text mimicking sometimes seen PDF->TXT exports)
    final lines = await File(filePath).readAsLines();
    bool readData = false;

    int dateIdx = -1;
    int descIdx = -1;
    int amountIdx = -1;
    int crDrIdx = -1;
    String delimiter = '~';

    for (final line in lines) {
      String trimmed = line.trim();
      
      // Check for exact headers to set up indices dynamically
      if (trimmed.contains('Transaction type~') || trimmed.contains('Transaction type~|~')) {
        delimiter = trimmed.contains('~|~') ? '~|~' : '~';
        final headers = trimmed.split(delimiter).map((e) => e.trim().toLowerCase()).toList();
        
        dateIdx = headers.indexOf('date');
        descIdx = headers.indexOf('description');
        amountIdx = headers.indexWhere((h) => h == 'amt' || h == 'amount');
        crDrIdx = headers.indexWhere((h) => h.contains('debit') || h.contains('credit') || h == 'cr/dr');
        
        // Ensure minimum columns are found
        if (dateIdx != -1 && descIdx != -1 && (amountIdx != -1 || crDrIdx != -1)) {
           readData = true;
        }
        continue;
      }

      if (readData) {
        if (trimmed.isEmpty || trimmed.contains('Opening NeuCoins') || trimmed.contains('Total Amount Due') || trimmed.startsWith('Opening')) break;
        
        final parts = trimmed.split(delimiter);
        // We only require enough parts to reach the max index we need
        final maxIdx = [dateIdx, descIdx, amountIdx, crDrIdx].reduce((curr, next) => curr > next ? curr : next);
        if (parts.length <= maxIdx) continue;

        final rawDate = parts[dateIdx].trim();
        final description = parts[descIdx].trim();
        final amountStr = amountIdx != -1 ? parts[amountIdx].trim() : '';
        final crDr = crDrIdx != -1 ? parts[crDrIdx].trim() : '';

        final amount = _parseAmount(amountStr);
        if (amount == null || amount <= 0) continue;

        final date = _parseDate(rawDate);
        if (date == null) continue;

        results.add(ParsedTransaction(
          date: date,
          description: description,
          debitAmount: crDr.toUpperCase() != 'CR' ? amount : null,
          creditAmount: crDr.toUpperCase() == 'CR' ? amount : null,
        ));
      }
    }

    if (results.isEmpty && (ext == 'csv' || ext == 'xlsx' || ext == 'xls')) {
      // If specific HDFC CSV failed, fallback to generic
      return _parseGenericRows(ext == 'csv' ? _readCsvFile(filePath) : _readExcelFile(filePath));
    }

    return results;
  }

  // ─── Generic CSV (any bank) ─────────────────────────────

  static Future<List<ParsedTransaction>> _parseGenericCsv(String filePath) async {
    final rows = _readCsvFile(filePath);
    return _parseGenericRows(rows);
  }

  static Future<List<ParsedTransaction>> _parseGenericExcel(String filePath) async {
    final rows = _readExcelFile(filePath);
    return _parseGenericRows(rows);
  }

  static List<ParsedTransaction> _parseGenericRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) throw Exception('File is empty');

    // Try to find the header row
    int headerIdx = -1;
    for (int i = 0; i < rows.length && i < 20; i++) {
      final r = rows[i].map((e) => e.toString().trim().toLowerCase()).toList();
      if (r.any((h) => h == 'date' || h.contains('datetime')) &&
          r.any((h) => h.contains('description') || h.contains('narration'))) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx == -1) {
      // Assume first row is header
      headerIdx = 0;
    }

    final headers = rows[headerIdx].map((e) => e.toString().trim().toLowerCase()).toList();
    final dateIdx = headers.indexWhere((h) => h == 'date' || h.contains('datetime'));
    final descIdx = headers.indexWhere((h) => h.contains('description') || h.contains('narration'));
    final debitIdx = headers.indexWhere((h) => h.contains('debit') || h.contains('withdrawal'));
    final creditIdx = headers.indexWhere((h) => h.contains('credit') || h.contains('deposit'));
    // Some CSVs have a single "Amount" column with sign
    final amountIdx = headers.indexWhere((h) => h == 'amount');

    // Optional labels for auto-mapping
    final accountIdx = headers.indexWhere((h) => h == 'account');
    final cardIdx = headers.indexWhere((h) => h == 'card');

    if (dateIdx == -1) throw Exception('Could not find Date column');
    if (descIdx == -1) throw Exception('Could not find Description/Narration column');

    final results = <ParsedTransaction>[];
    for (int i = headerIdx + 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.isEmpty || r.length <= dateIdx) continue;
      final rawDate = r[dateIdx].toString().trim();
      if (rawDate.isEmpty) continue;
      final date = _parseDate(rawDate);
      if (date == null) continue;

      final description = r.length > descIdx ? r[descIdx].toString().trim() : '';

      double? debit;
      double? credit;

      if (debitIdx >= 0 && creditIdx >= 0) {
        debit = r.length > debitIdx ? _parseAmount(r[debitIdx].toString()) : null;
        credit = r.length > creditIdx ? _parseAmount(r[creditIdx].toString()) : null;
      } else if (amountIdx >= 0) {
        final amt = _parseAmount(r[amountIdx].toString());
        if (amt != null) {
          if (amt < 0) {
            debit = amt.abs();
          } else {
            credit = amt;
          }
        }
      }

      if ((debit != null && debit > 0) || (credit != null && credit > 0)) {
        final accountName = accountIdx >= 0 && r.length > accountIdx ? r[accountIdx].toString().trim() : null;
        final cardName = cardIdx >= 0 && r.length > cardIdx ? r[cardIdx].toString().trim() : null;

        results.add(ParsedTransaction(
          date: date,
          description: description,
          debitAmount: debit,
          creditAmount: credit,
          accountName: accountName?.isNotEmpty == true ? accountName : null,
          cardName: cardName?.isNotEmpty == true ? cardName : null,
        ));
      }
    }
    return results;
  }

  // ─── File reading helpers ───────────────────────────────

  static List<List<dynamic>> _readCsvFile(String filePath) {
    final input = File(filePath).readAsStringSync();
    return const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(input);
  }

  static List<List<dynamic>> _readExcelFile(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) throw Exception('Excel file is empty');
      final sheet = excel.tables[excel.tables.keys.first]!;
      return sheet.rows.map((row) => row.map((cell) => cell?.value ?? '').toList()).toList();
    } catch (e, st) {
      throw Exception('Failed to read Excel file: $e\n$st');
    }
  }

  // ─── Value parsing helpers ──────────────────────────────

  static double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty || cleaned == 'null' || cleaned == 'NA') return null;
    return double.tryParse(cleaned);
  }

  static final _dateFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd/MM/yy'), // Handles 01/09/25 instead of 2025
    DateFormat('dd/MM/yyyy HH:mm:ss'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('yyyy/MM/dd'),
  ];

  static String? _parseDate(String raw) {
    // Already in yyyy-MM-dd
    final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}');
    if (isoPattern.hasMatch(raw)) {
      return raw.substring(0, 10);
    }
    for (final fmt in _dateFormats) {
      try {
        final dt = fmt.parseStrict(raw.trim());
        // Prevent 2-digit years parsed by 4-digit year patterns (e.g. 0026) instead of correct century.
        if (dt.year < 2000) continue;
        return DateFormat('yyyy-MM-dd').format(dt);
      } catch (_) {
        // try next
      }
    }
    return null;
  }
}
