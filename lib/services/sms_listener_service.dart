import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sms_parsing_service.dart';

class SmsListenerService {
  static final Telephony telephony = Telephony.instance;
  static const String _lastSmsReadKey = 'last_sms_read_timestamp';

  /// Returns true if the address contains at least one alphabet letter.
  /// (e.g. AD-HDFCBK, VM-KOTAKB). Personal mobile numbers strictly contain digits/+.
  static bool _isCommercialSender(String address) {
    return RegExp(r'[a-zA-Z]').hasMatch(address);
  }

  static Future<void> syncInboxMessages(ProviderContainer container, {void Function(int, int)? onProgress}) async {
    // Request permissions
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    
    if (permissionsGranted != null && permissionsGranted) {
      
      final prefs = await SharedPreferences.getInstance();
      final lastReadTimestamp = prefs.getInt(_lastSmsReadKey);

      List<SmsMessage> messages;

      if (lastReadTimestamp == null) {
        // First run: fetch all messages
        messages = await telephony.getInboxSms(
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)], // Process oldest unsynced first
        );
      } else {
        // Fetch SMS messages strictly newer than the last check
        messages = await telephony.getInboxSms(
          filter: SmsFilter.where(SmsColumn.DATE).greaterThan(lastReadTimestamp.toString()),
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)], // Process oldest unsynced first
        );
      }


      int total = messages.length;
      if (total == 0) {
        onProgress?.call(0, 0);
      }

      int latestTimestamp = lastReadTimestamp ?? 0;

      for (int i = 0; i < total; i++) {
        var message = messages[i];
        if (message.address != null && message.body != null) {
          if (_isCommercialSender(message.address!)) {
            try {
              await SmsParsingService.processIncomingSms(message.address!, message.body!, container, timestamp: message.date);
            } catch (e) {
              // Ignore individual parsing errors during bulk sync
            }
          }
        }
        
        // Save the timestamp for each successfully passed message so we don't re-process on crash
        if (message.date != null && message.date! > latestTimestamp) {
          latestTimestamp = message.date!;
          await prefs.setInt(_lastSmsReadKey, latestTimestamp);
        }
        
        onProgress?.call(i + 1, total);
      }

    } else {
      onProgress?.call(0, 0);
    }
  }
}
