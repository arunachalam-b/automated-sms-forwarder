import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart'; // Needed for WidgetsFlutterBinding
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/filter.dart' as custom_filter;
import '../utils/database_helper.dart';
import '../models/forwarded_sms_log.dart';
import 'sms_handler.dart'; // Import the dedicated SMS handler

// --- Configuration ---
const String notificationChannelId = 'auto_sms_channel';
const int notificationId = 888;
const String notificationChannelName = 'Auto SMS Forwarder';
const String notificationDescription = 'Notifications for SMS forwarding service';
const String notificationContent = 'SMS forwarding service is running';
const String initialNotificationTitle = 'Auto SMS Service';
const String stopServiceAction = 'stopService';

// Forwarding notification constants
const String forwardingNotificationChannelId = 'sms_forwarding_channel';
const String forwardingNotificationChannelName = 'SMS Forwarding';
const String forwardingNotificationDescription = 'Notifications about forwarded messages';

// Add a global variable to track service initialization attempts
int _serviceInitializationAttempts = 0;
const int _maxServiceInitializationAttempts = 2;

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
    
    // Register the main service channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: notificationDescription,
      importance: Importance.high,
    ));
    
    // Also register the SMS forwarding notification channel 
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      forwardingNotificationChannelId,
      forwardingNotificationChannelName,
      description: forwardingNotificationDescription,
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
  Timer.periodic(const Duration(minutes: 2), (timer) {
    print('[BG Service] Service heartbeat - still alive');
  });

  // --- SMS Listening Logic --- 
  print('[BG Service] Setting up SMS listener...');
  await _initializeSmsListener(service);
}

// Separate function to make SMS setup more manageable
Future<void> _initializeSmsListener(ServiceInstance service) async {
  try {
    // Track initialization attempts to prevent infinite retries
    _serviceInitializationAttempts++;
    print('[SMS Init] Beginning SMS listener setup (Attempt $_serviceInitializationAttempts of $_maxServiceInitializationAttempts)');
    
    // Initialize telephony instance
    final Telephony telephony = Telephony.instance;
    print('[SMS Init] Telephony instance created');
    
    // Initialize database helper
    final dbHelper = DatabaseHelper();
    print('[SMS Init] Database helper initialized');

    // Add retry mechanism for permission check with delay
    bool smsPermission = false;
    bool phonePermission = false;
    int retryCount = 0;
    
    while (retryCount < 3 && (!smsPermission || !phonePermission)) {
      // Check permissions explicitly without requesting them
      print('[SMS Init] Checking SMS permissions (attempt ${retryCount + 1})');
      smsPermission = await Permission.sms.status.isGranted;
      phonePermission = await Permission.phone.status.isGranted;
      
      print('[SMS Init] Permission status - SMS: $smsPermission, Phone: $phonePermission');
      
      if (!smsPermission || !phonePermission) {
        // Wait a moment before retrying
        print('[SMS Init] Permissions not detected yet, waiting before retry...');
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      } else {
        break; // Permissions are granted, proceed
      }
    }

    if (smsPermission && phonePermission) {
      print('[SMS Init] All permissions granted, setting up SMS listener');
      
      // Reset initialization counter on success
      _serviceInitializationAttempts = 0;
      
      // Update notification to show we're setting up
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: initialNotificationTitle,
          content: "Setting up SMS listener...",
        );
      }

      // Listen for incoming SMS messages
      print('[SMS Init] Registering onNewMessage handler');
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          print('[SMS RECEIVED] From: ${message.address}, Body: ${message.body?.substring(0, min(20, message.body?.length ?? 0))}...');
          
          // Update notification immediately
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "New SMS Received",
              content: "From: ${message.address ?? 'Unknown'}",
            );
          }
          
          // Process the SMS using the dedicated handler
          try {
            print('[SMS Process] Processing incoming SMS');
            await processIncomingSms(message, dbHelper, telephony);
            print('[SMS Process] SMS processed successfully');
          } catch (e) {
            print('[SMS Process] Error processing SMS: $e');
          }
        },
        onBackgroundMessage: backgroundMessageHandler, // Use the dedicated background handler
        listenInBackground: true  // Enable proper background handling
      );

      print('[SMS Init] SMS listener registered successfully');
      
      // Update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: initialNotificationTitle,
          content: "Listening for SMS messages",
        );
      }
      
      // Test if the listener is working by sending a log message every minute
      Timer.periodic(const Duration(minutes: 1), (timer) {
        print('[SMS Listener Check] SMS listener should be active: ${DateTime.now()}');
      });
      
    } else {
      print('[SMS Init] Required permissions not granted after retries');
      
      // Use a less alarming notification since we've already tried to verify permissions
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "SMS Service",
          content: "Waiting for permissions to be granted",
        );
      }
      
      // Try again after a longer delay ONLY if we haven't exceeded max attempts
      if (_serviceInitializationAttempts < _maxServiceInitializationAttempts) {
        print('[SMS Init] Will attempt to reinitialize SMS listener after delay (attempt $_serviceInitializationAttempts of $_maxServiceInitializationAttempts)');
        Future.delayed(const Duration(seconds: 5), () {
          _initializeSmsListener(service);
        });
      } else {
        print('[SMS Init] Max initialization attempts reached. Will not retry automatically.');
        // Use the standard notification instead of the "limited mode" message
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: initialNotificationTitle,
            content: notificationContent,
          );
        }
      }
    }
    
  } catch (e) {
    print('[SMS Init] Exception during SMS initialization: $e');
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Service Error",
        content: "Failed to initialize SMS listener",
      );
    }
  }
}
