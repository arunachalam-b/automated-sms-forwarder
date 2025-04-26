import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart'; // Needed for WidgetsFlutterBinding
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
// Remove local notifications setup - background service handles its own foreground notification
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/filter.dart' as custom_filter;
import '../utils/database_helper.dart';
import '../models/forwarded_sms_log.dart';

// --- Configuration ---
const String notificationChannelId = 'auto_sms_channel';
const int notificationId = 888;
const String notificationChannelName = 'Auto SMS Forwarder';
const String notificationDescription = 'Notifications for SMS forwarding service';
const String notificationContent = 'SMS forwarding service is running';
const String initialNotificationTitle = 'Auto SMS Service';
const String stopServiceAction = 'stopService';

// --- Background Service Initialization ---
Future<void> initializeBackgroundService() async {
  // Initialize notification channel first - this is critical
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: notificationDescription,
      importance: Importance.high,
    ));
  }

  // Initialize background service
  final service = FlutterBackgroundService();

  // Configure service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: initialNotificationTitle,
      initialNotificationContent: notificationContent,
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// --- iOS Background Handler ---
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  print('iOS Background Service Handler (Limited Functionality)');
  return true;
}

// --- Main Background Entry Point (onStart) ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // **Crucial for background isolates**
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  print('[BG Service] Starting background service...');

  // Show initial notification for Android
  if (service is AndroidServiceInstance) {
    // Set up foreground notification properly
    service.setAsForegroundService();
    
    // Listen for service mode changes
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Stop service listener
  service.on(stopServiceAction).listen((event) {
    print('[BG Service] Stop requested, shutting down...');
    service.stopSelf();
  });

  // Basic status update (optional)
  Timer.periodic(const Duration(minutes: 15), (timer) {
    print('[BG Service] Service heartbeat');
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: initialNotificationTitle,
        content: "Running since ${DateTime.now().difference(DateTime.now().subtract(const Duration(minutes: 15) * timer.tick)).inMinutes} min",
      );
    }
  });

  // --- Move SMS Listening Logic HERE --- 
  print('[BG Service] Setting up SMS listener...');
  final Telephony telephony = Telephony.instance;
  final dbHelper = DatabaseHelper();

  // Permissions should ideally be granted before starting the service via UI,
  // but we can double-check here.
  bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

  if (permissionsGranted ?? false) {
    print('[BG Service] Permissions granted. Starting SMS listener...');

    // Update notification to indicate we're setting up
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: initialNotificationTitle,
        content: "Setting up SMS listener...",
      );
    }

    // Set up the listener within the background isolate
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async { // Use correct type: SmsMessage
        print('[BG Service] ---->>>> SMS RECEIVED! From: ${message.address}, Body: ${message.body?.substring(0, (message.body?.length ?? 0) > 20 ? 20 : (message.body?.length ?? 0))}...');
        
        // Update notification to show we received a message
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "New SMS Received",
            content: "From: ${message.address ?? 'Unknown'} - Processing...",
          );
        }
        
        // Now call the processing function
        try {
          await processIncomingSms(message, dbHelper, telephony);
          
          // Update notification after processing
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: initialNotificationTitle,
              content: "Last SMS processed at ${DateTime.now().hour}:${DateTime.now().minute}",
            );
          }
        } catch (e) {
          print('[BG Service] Error processing SMS: $e');
          
          // Update notification to show error
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: initialNotificationTitle,
              content: "Error processing last SMS",
            );
          }
        }
      },
      listenInBackground: false // Service handles the background execution
    );

    print('[BG Service] SMS Listener registered.');
    
    // Update notification to show active listening
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: initialNotificationTitle, 
        content: "Actively listening for messages...",
      );
    }
  } else {
    print('[BG Service] SMS Permissions NOT granted. Stopping service.');
    
    // Update notification to show error
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: initialNotificationTitle, 
        content: "SMS Permission Denied. Service Stopped.",
      );
    }
    
    await Future.delayed(const Duration(seconds: 3)); // Give time for notification update
    service.stopSelf();
  }
}

// --- Shared SMS Processing Logic (Keep as is) ---
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

// --- Logging Logic (Keep as is) ---
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