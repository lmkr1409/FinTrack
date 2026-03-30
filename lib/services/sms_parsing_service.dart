import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/merchant.dart';
import '../models/transaction_rule.dart';
import '../models/merchant_rule.dart';
import '../services/providers.dart';
import 'ml_service.dart';


class SmsParsingService {
  /// Entry point for an incoming SMS.
  static Future<void> processIncomingSms(String sender, String body, ProviderContainer container, {int? timestamp}) async {
    try {
      // Fetch dynamic labeling rules first to check sender rules
      final mRuleRepo = container.read(merchantRuleRepositoryProvider);
      final merchantRules = await mRuleRepo.getAll();
      final tRuleRepo = container.read(transactionRuleRepositoryProvider);
      final transactionRules = await tRuleRepo.getAll();

      // Step 1: Check if message is from an approved bank.
      final lowerBody = body.toLowerCase();
      final bankSenderRules = transactionRules.where((r) => r.ruleType == 'BANK_SENDER').toList();
      
      bool isBankSender = false;
      if (bankSenderRules.isEmpty) {
        // Fallback default
        isBankSender = RegExp(r'^[A-Za-z]{2}-[A-Za-z0-9\-]{3,}$').hasMatch(sender);
      } else {
        // Must match one of the configured bank senders
        final lowerSender = sender.toLowerCase();
        for (var rule in bankSenderRules) {
          if (lowerSender.contains(rule.pattern.toLowerCase())) {
            isBankSender = true;
            break;
          }
        }
      }

      final hasKeywords = lowerBody.contains('debited') || lowerBody.contains('credited') || 
                          lowerBody.contains('spent') || lowerBody.contains('a/c') || 
                          lowerBody.contains('acct') || lowerBody.contains('txn') || 
                          lowerBody.contains('rs.') || lowerBody.contains('inr') ||
                          lowerBody.contains('upi') || lowerBody.contains('bank card');

      if (!isBankSender) {
        return; // Discard non-bank messages (e.g. Tata Neu)
      }
      if (!hasKeywords) {
        return; // Discard non-transactional messages
      }
      
      // Step 2: Rule-based parsing
      var parsedData = _applyRuleBasedParsing(body, transactionRules, merchantRules);
      
      // Step 4: ML fallback if rules fail to get amount and type
      if (parsedData['amount'] == null || parsedData['transactionType'] == null) {
        final mlData = await MlService.parseTransactionInfo(body);
        if (mlData != null) {
          parsedData = { ...parsedData, ...mlData };
        }
      }


      // If still missing essential info or if it's not a CREDIT/DEBIT/TRANSFER, discard
      var type = parsedData['transactionType'];
      if (type != 'DEBIT' && type != 'CREDIT' && type != 'TRANSFER') {
        return; 
      }
      final amount = parsedData['amount'] as double?;
      if (amount == null || amount <= 0) {
        return; 
      }

      final merchantName = parsedData['merchantName'] as String? ?? 'Unknown Merchant';

      // Step 3: Merchant details categorization
      final merchantRepo = container.read(merchantRepositoryProvider);
      final allMerchants = await merchantRepo.getAll();
      Merchant? matchedMerchant;
      for (var m in allMerchants) {
        if (m.merchantName.toLowerCase() == merchantName.toLowerCase()) {
          matchedMerchant = m;
          break;
        }
      }

      int? categoryId = parsedData['categoryId'];
      int? subcategoryId = parsedData['subcategoryId'];
      int? purposeId = parsedData['purposeId'];
      int? accountId = parsedData['accountId'];
      int? cardId = parsedData['cardId'];
      int? paymentMethodId = parsedData['paymentMethodId'];

      if (cardId == null && parsedData['cardNumber'] != null) {
        final cardRepo = container.read(cardRepositoryProvider);
        final allCards = await cardRepo.getAll();
        String lastFour = parsedData['cardNumber'];
        for (var c in allCards) {
          if (c.cardNumber.contains(lastFour)) {
            cardId = c.id;
            break;
          }
        }
      }

      if (matchedMerchant == null && parsedData['merchantId'] != null) {
        try {
          matchedMerchant = allMerchants.firstWhere((m) => m.id == parsedData['merchantId']);
        } catch (_) {}
      }

      if (matchedMerchant == null) {
        // Step 6: ML Fallback for categorization
        final categoryData = await MlService.categorizeMerchant(merchantName);
        if (categoryData != null) {
           categoryId ??= categoryData['categoryId'];
           subcategoryId ??= categoryData['subcategoryId'];
           purposeId ??= categoryData['purposeId'];
        }
      }

      // Find "SMS_READING" expense source
      final sourceRepo = container.read(expenseSourceRepositoryProvider);
      final allSources = await sourceRepo.getAll();
      final smsSource = allSources.firstWhere(
        (s) => s.expenseSourceName == 'SMS_READING',
        orElse: () {
          return allSources.isNotEmpty ? allSources.first : throw StateError('No expense sources available');
        },
      );

      // Create the transaction
      final transactionDate = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.now();

      // Determine nature based on type and category
      String nature = 'TRANSACTIONS';
      if (type == 'TRANSFER') {
        nature = 'TRANSFERS';
        type = 'DEBIT'; // Enforce DEBIT as base type for outward transfer
      }

      // If category is identified, inherit its exact type as nature
      if (categoryId != null) {
        final catRepo = container.read(categoryRepositoryProvider);
        final category = await catRepo.getById(categoryId);
        if (category != null) {
          nature = category.categoryType;
        }
      }

      // A transaction is only "auto-labeled" if ALL critical fields were determined by rules or ML
      final isFullyParsed = categoryId != null &&
          matchedMerchant?.id != null &&
          paymentMethodId != null &&
          accountId != null &&
          cardId != null;
          // Note: amount and type are already guaranteed non-null by earlier guards

      final newTransaction = Transaction(
        transactionType: type as String,
        nature: nature,
        amount: amount,
        transactionDate: transactionDate.toIso8601String(),
        description: body,
        merchantId: matchedMerchant?.id,
        expenseSourceId: smsSource.id,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        purposeId: purposeId,
        accountId: accountId,
        cardId: cardId,
        paymentMethodId: paymentMethodId,
        isAutoLabeled: isFullyParsed,
        labeled: false,
      );

      final txnRepo = container.read(transactionRepositoryProvider);
      final insertedId = await txnRepo.insertTransaction(newTransaction);

    } catch (e, stackTrace) {
    }
  }

  static Map<String, dynamic> _applyRuleBasedParsing(String text, List<TransactionRule> tRules, List<MerchantRule> mRules) {
    Map<String, dynamic> result = {};
    final lower = text.toLowerCase();

    // 1. Find Amount Regex rules and apply
    final amountRules = tRules.where((r) => r.ruleType == 'AMOUNT_REGEX').toList();
    bool amountFound = false;
    for (var rule in amountRules) {
      try {
        final match = RegExp(rule.pattern, caseSensitive: false).firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          final amountStr = match.group(1)!.replaceAll(',', '');
          final amount = double.tryParse(amountStr);
          if (amount != null) {
            result['amount'] = amount;
            amountFound = true;
            break;
          }
        }
      } catch (e) {
      }
    }

    if (!amountFound) {
      // Fallback default regex
      final amountMatch = RegExp(r'(?:(?:[Rr]s\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?))').firstMatch(text);
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)!.replaceAll(',', '');
        result['amount'] = double.tryParse(amountStr);
      }
    }

    // 2. Transaction Type rules
    final typeRules = tRules.where((r) => r.ruleType == 'TRANSACTION_TYPE').toList();
    for (var rule in typeRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        result['transactionType'] = rule.mappedType;
        break; // Assume first matched type wins
      }
    }

    // 3. Payment Method rules
    final methodRules = tRules.where((r) => r.ruleType == 'PAYMENT_METHOD').toList();
    for (var rule in methodRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        result['paymentMethodId'] = rule.paymentMethodId;
        break;
      }
    }

    // 4. Account rules
    final accountRules = tRules.where((r) => r.ruleType == 'ACCOUNT').toList();
    for (var rule in accountRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        result['accountId'] = rule.accountId;
        break;
      }
    }

    // 5. Card rules
    final cardRules = tRules.where((r) => r.ruleType == 'CARD').toList();
    for (var rule in cardRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        result['cardId'] = rule.cardId;
        break;
      }
    }

    // 6. Merchant rules
    for (var rule in mRules) {
      if (lower.contains(rule.keyword.toLowerCase())) {
        if (rule.merchantId != null) result['merchantId'] = rule.merchantId;
        if (rule.categoryId != null) result['categoryId'] = rule.categoryId;
        if (rule.subcategoryId != null) result['subcategoryId'] = rule.subcategoryId;
        if (rule.purposeId != null) result['purposeId'] = rule.purposeId;
        break; // Assume first matched merchant wins
      }
    }

    // 7. Fallback Merchant extraction (if no merchant rule matched)
    if (result['merchantId'] == null) {
      String? merchant;
      final atMatch = RegExp(r'[Aa]t\s+([A-Za-z0-9@.\ \-]+?)(?=\s*(?:[Oo]n|[Bb]y)\b|\n|$)', caseSensitive: false).firstMatch(text);
      final toMatch = RegExp(r'[Tt]o\s+([A-Za-z0-9@.\ \-]+?)(?=\s*(?:[Oo]n|[Rr]ef|[Vv]ia|[Uu]mrn)\b|\n|$)', caseSensitive: false).firstMatch(text);
      final towardsMatch = RegExp(r'[Tt]owards\s+([A-Za-z0-9@.\ \-]+?)(?=\s*(?:[Oo]n|[Uu]mrn)\b|\n|$)', caseSensitive: false).firstMatch(text);
      final fromVpaMatch = RegExp(r'[Ff]rom\s+[Vv][Pp][Aa]\s+([A-Za-z0-9@.\-]+)', caseSensitive: false).firstMatch(text);
      final forMatch = RegExp(r'[Ff]or\s+([A-Za-z0-9@.\ \-]+?)(?=\s*(?:[Oo]n|[Rr]ef|\d)\b|\n|$)', caseSensitive: false).firstMatch(text);

      if (atMatch != null) { merchant = atMatch.group(1)!.trim(); }
      else if (toMatch != null) { merchant = toMatch.group(1)!.trim(); }
      else if (towardsMatch != null) { merchant = towardsMatch.group(1)!.trim(); }
      else if (fromVpaMatch != null) { merchant = fromVpaMatch.group(1)!.trim(); }
      else if (forMatch != null) { merchant = forMatch.group(1)!.trim(); }

      if (merchant != null && merchant.isNotEmpty && merchant.toLowerCase() != 'your' && !merchant.toLowerCase().startsWith('a/c')) {
        result['merchantName'] = merchant;
      }
    }

    // 8. Fallback Card extraction (if no card rule matched)
    if (result['cardId'] == null) {
      final accMatch = RegExp(r'(?:a[/\\]?c|acct|account|card)\s*(?:[Nn]o)?.*?(?:\b|[Xx]|\*)*([0-9]{4})\b', caseSensitive: false).firstMatch(text);
      if (accMatch != null) {
        result['cardNumber'] = accMatch.group(1);
      }
    }

    return result;
  }
}
