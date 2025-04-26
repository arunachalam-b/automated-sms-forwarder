import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart'; // Needed for WidgetsFlutterBinding
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/filter.dart' as custom_filter;
import '../utils/database_helper.dart';
import '../models/forwarded_sms_log.dart';

// --- Configuration ---
const String notificationChannelId = 'auto_sms_channel';
const int notificationId = 888;
const String notificationChannelName = 'Auto SMS Forwarder';
const String notificationContent = 'Listening for SMS messages to forward';
const String initialNotificationTitle = 'Auto SMS Service';
const String stopServiceAction = 'stopService';

// --- Background Service Initialization ---
Future<void> initializeBackgroundService() async {
  // final service = FlutterBackgroundService();
  final telephony = Telephony.instance;

  // // --- Android Notification Channel ---
  // // Required for foreground service notification
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //   FlutterLocalNotificationsPlugin();
  //   AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  //     notificationChannelId,
  //     notificationChannelName,
  //     description: 'This channel is used for SMS forwarding notifications',
  //     importance: Importance.high,
  //     playSound: true,
  //     enableVibration: true,
  //   );
  // await flutterLocalNotificationsPlugin
  //   .resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>()
  //   ?.createNotificationChannel(notificationChannel);
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: true, // Start service automatically on boot (requires RECEIVE_BOOT_COMPLETED permission)
  //     isForegroundMode: true,
  //     notificationChannelId: notificationChannelId,
  //     initialNotificationTitle: initialNotificationTitle,
  //     initialNotificationContent: notificationContent,
  //     foregroundServiceNotificationId: notificationId,
  //     // autoStartOnBoot: true, // Consider adding this later if needed
  //   ),
  //   // iOS configuration (placeholder, as background SMS listening is limited on iOS)
  //   iosConfiguration: IosConfiguration(
  //     autoStart: true,
  //     onForeground: onStart, // Run logic in foreground too if app is open
  //     onBackground: onIosBackground, // Special handler for iOS background
  //   ),
  // );
  telephony.listenIncomingSms(
		onNewMessage: (dynamic message) {
			// Handle message
      print("New message received =================== ");
      print("Sender: ${message} ================ ");

      Telephony.backgroundInstance.sendSms(to: "9266396714", message: "Message from background");
		},
		listenInBackground: false
	);
}

// --- iOS Background Handler (Limited Functionality) ---
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print(' =================================== iOS Background Service Handler');
  // iOS background execution for SMS is very restricted.
  // We likely cannot listen for SMS reliably here.
  return true; // Return true to keep service running (though it might not do much)
}

// @pragma('vm:entry-point')
// backgroundMessageHandler(dynamic message) async {
// 	// Handle background message
// 	Telephony.backgroundInstance.sendSms(to: "123456789", message: "Message from background");
// }

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("Calling onStart =================== ");
}

// --- Main Background Entry Point (Android Mostly) ---
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   // Initialize Dart plugins
//   DartPluginRegistrant.ensureInitialized();

//   // Special setup for Android background service
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   // Stop service listener
//   service.on(stopServiceAction).listen((event) {
//     service.stopSelf();
//   });

//   // --- Main Logic: Listen for SMS --- 
//   print(' =================================== Background Service Started ====================================================== ');
//   final Telephony telephony = Telephony.instance;
//   final dbHelper = DatabaseHelper(); // Initialize DB Helper in background

//   // Request necessary permissions if not already handled
//   // Note: It's better to request permissions from the UI before starting the service
//   bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

//   if (permissionsGranted ?? false) {
//     print(' =================================== SMS Permissions granted in background service. ====================================================== ');

//     telephony.listenIncomingSms(
//         onNewMessage: (SmsMessage message) async {
//           print(' =================================== Background Service: New SMS Received - ${message.address} : ${message.body?.substring(0, 10)}... ================================== ');
//           await processIncomingSms(message, dbHelper, telephony);
//         },
//         listenInBackground: false // We are already in the background service
//         );
//   } else {
//      print(' =================================== SMS Permissions NOT granted in background service. Stopping.');
//       // Optionally, notify the UI or stop the service
//      service.stopSelf();
//   }

//   // Keep the service alive
//   service.invoke('updateNotification', {'content': 'Listening for messages...'});
// }

// // --- Shared SMS Processing Logic ---
// Future<void> processIncomingSms(SmsMessage message, DatabaseHelper dbHelper, Telephony telephony) async {
//   if (message.body == null || message.address == null) {
//     print(' =================================== Received incomplete SMS data.');
//     return;
//   }

//   try {
//     final filters = await dbHelper.getAllFilters();
//     print(' =================================== Loaded ${filters.length} filters for matching. ===================================== ');

//     custom_filter.Filter? matchedFilter;

//     for (final filter in filters) {
//       bool allConditionsMet = true;
//       if (filter.conditions.isEmpty) {
//           allConditionsMet = false; // Require at least one condition
//           continue;
//       }

//       for (final condition in filter.conditions) {
//         bool conditionMet = false;
//         String? smsValue;

//         if (condition.type == custom_filter.FilterConditionType.sender) {
//           smsValue = message.address; // Check against sender address
//         }
//         else { // FilterConditionType.content
//           smsValue = message.body;
//         }

//         if (smsValue == null) {
//             allConditionsMet = false;
//             break; // Cannot evaluate if value is null
//         }

//         // Perform comparison
//         if (condition.type == custom_filter.FilterConditionType.content && condition.caseSensitive) {
//           conditionMet = smsValue.contains(condition.value);
//         } else {
//           conditionMet = smsValue.toLowerCase().contains(condition.value.toLowerCase());
//         }

//         if (!conditionMet) {
//           allConditionsMet = false;
//           break; // No need to check other conditions for this filter
//         }
//       }

//       if (allConditionsMet) {
//         matchedFilter = filter;
//         print(' =================================== Filter matched: ${filter.id}');
//         break; // Found the first matching filter
//       }
//     }

//     // --- Send SMS if matched ---
//     if (matchedFilter != null && matchedFilter.recipients.isNotEmpty) {
//       print(' =================================== Forwarding SMS to: ${matchedFilter.recipients.join(", ")}');
//       // bool allSent = true; // Can track overall success if needed

//       for (final recipient in matchedFilter.recipients) {
//         String status = 'Failed'; // Default to failed
//         String? errorMessage;
//         try {
//           String forwardMessage = "Fwd from ${message.address ?? 'Unknown Sender'}:\n${message.body ?? '[Empty Body]'}";

//           await telephony.sendSms(
//             to: recipient,
//             message: forwardMessage,
//           );
//           print(' =================================== Successfully forwarded to $recipient');
//           status = 'Sent'; // Update status on success
//         } catch (e) {
//           // allSent = false;
//           errorMessage = e.toString();
//           print(' =================================== Error sending SMS to $recipient: $errorMessage');
//         }

//         // --- Log the attempt --- 
//         await logForwardedSms(
//             dbHelper,
//             message,
//             recipient,
//             matchedFilter.id,
//             status,
//             errorMessage,
//          );
//       }
//     } else {
//       print(' =================================== No matching filter found or filter has no recipients.');
//     }

//   } catch (e) {
//     print(' =================================== Error processing SMS: $e');
//     // Consider logging this error as well, maybe with a special status
//   }
// }

// // --- Logging Logic --- 
// Future<void> logForwardedSms(
//     DatabaseHelper dbHelper,
//     SmsMessage originalMessage,
//     String forwardedTo,
//     String filterId,
//     String status,
//     String? errorMessage,
//   ) async {

//   print(' ===================================  =================================== Logging forwarded message: ${originalMessage.address} -> $forwardedTo (Status: $status)');
//   final logEntry = ForwardedSmsLog(
//     // id generated automatically by model
//     filterId: filterId,
//     originalSender: originalMessage.address ?? 'Unknown Sender',
//     forwardedTo: forwardedTo,
//     messageContent: originalMessage.body ?? '',
//     dateTime: DateTime.now(), // Log time of forwarding attempt
//     status: status,
//     errorMessage: errorMessage,
//   );
//   try {
//     await dbHelper.insertForwardedSmsLog(logEntry);
//   } catch (e) {
//      print(" =================================== Error inserting SMS log into database: $e =================================== ");
//      // Decide how to handle DB insertion errors - maybe retry later?
//   }
// } 