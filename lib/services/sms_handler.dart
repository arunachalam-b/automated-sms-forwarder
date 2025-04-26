import 'package:another_telephony/telephony.dart';
import '../models/filter.dart' as custom_filter;
import '../utils/database_helper.dart';
import '../models/forwarded_sms_log.dart';

// Root level annotated function for the background message handler
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  print('[BG Handler] SMS received in pure background handler');
  
  try {
    // Initialize dependencies
    final dbHelper = DatabaseHelper();
    final telephony = Telephony.instance;
    
    await processIncomingSms(message, dbHelper, telephony);
    print('[BG Handler] Successfully processed SMS in background');
  } catch (e) {
    print('[BG Handler] Error in background handler: $e');
  }
}

// Shared SMS processing logic
Future<void> processIncomingSms(SmsMessage message, DatabaseHelper dbHelper, Telephony telephony) async {
  if (message.body == null || message.address == null) {
    print('[ProcessSMS] Received incomplete SMS data.');
    return;
  }
  try {
    final filters = await dbHelper.getAllFilters();
    print('[ProcessSMS] Loaded ${filters.length} filters for matching.');
    custom_filter.Filter? matchedFilter;
    for (final filter in filters) {
      bool allConditionsMet = true;
      if (filter.conditions.isEmpty) {
          allConditionsMet = false;
          continue;
      }
      for (final condition in filter.conditions) {
        bool conditionMet = false;
        String? smsValue;
        if (condition.type == custom_filter.FilterConditionType.sender) {
          smsValue = message.address;
        }
        else { // FilterConditionType.content
          smsValue = message.body;
        }
        if (smsValue == null) {
            allConditionsMet = false;
            break;
        }
        if (condition.type == custom_filter.FilterConditionType.content && condition.caseSensitive) {
          conditionMet = smsValue.contains(condition.value);
        } else {
          conditionMet = smsValue.toLowerCase().contains(condition.value.toLowerCase());
        }
        if (!conditionMet) {
          allConditionsMet = false;
          break;
        }
      }
      if (allConditionsMet) {
        matchedFilter = filter;
        print('[ProcessSMS] Filter matched: ${filter.id}');
        break;
      }
    }
    if (matchedFilter != null && matchedFilter.recipients.isNotEmpty) {
      print('[ProcessSMS] Forwarding SMS to: ${matchedFilter.recipients.join(", ")}');
      for (final recipient in matchedFilter.recipients) {
        String status = 'Failed';
        String? errorMessage;
        try {
          String forwardMessage = "Fwd from ${message.address ?? 'Unknown Sender'}:\n${message.body ?? '[Empty Body]'}";
          await telephony.sendSms(to: recipient, message: forwardMessage);
          print('[ProcessSMS] Successfully forwarded to $recipient');
          status = 'Sent';
        } catch (e) {
          errorMessage = e.toString();
          print('[ProcessSMS] Error sending SMS to $recipient: $errorMessage');
        }
        await logForwardedSms(dbHelper, message, recipient, matchedFilter.id, status, errorMessage);
      }
    } else {
      print('[ProcessSMS] No matching filter found or filter has no recipients.');
    }
  } catch (e) {
    print('[ProcessSMS] Error processing SMS: $e');
  }
}

// Logging function
Future<void> logForwardedSms(DatabaseHelper dbHelper, SmsMessage originalMessage, String forwardedTo, String filterId, String status, String? errorMessage) async {
  print('[LogSMS] Logging forwarded message: ${originalMessage.address} -> $forwardedTo (Status: $status)');
  final logEntry = ForwardedSmsLog(
    filterId: filterId,
    originalSender: originalMessage.address ?? 'Unknown Sender',
    forwardedTo: forwardedTo,
    messageContent: originalMessage.body ?? '',
    dateTime: DateTime.now(),
    status: status,
    errorMessage: errorMessage,
  );
  try {
    await dbHelper.insertForwardedSmsLog(logEntry);
  } catch (e) {
     print("[LogSMS] Error inserting SMS log into database: $e");
  }
} 