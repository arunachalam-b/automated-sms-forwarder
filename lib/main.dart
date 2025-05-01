import 'package:auto_sms_2/services/sms_handler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_page.dart';
import 'screens/permissions_screen.dart';
import 'services/background_service.dart';
import 'package:another_telephony/telephony.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await initializeBackgroundService();

  // Register the callback handler for background messages
  // This MUST be done before any SMS handling is attempted
  final telephony = Telephony.instance;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      // This function will be called when the app is in the foreground
      print('[Main] Received SMS in foreground: $message');
      backgroundMessageHandler(message);
    },
    onBackgroundMessage: backgroundMessageHandler,
    listenInBackground: true,
  );

  // Load saved theme mode
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('themeMode');
  final initialThemeMode = savedThemeMode != null
      ? ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedThemeMode,
          orElse: () => ThemeMode.system,
        )
      : ThemeMode.system;

  runApp(MyApp(initialThemeMode: initialThemeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _handleThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto SMS Forwarder',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3498DB),
          secondary: Color(0xFF3498DB),
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3498DB),
            side: const BorderSide(color: Color(0xFF3498DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A2025),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3498DB),
          secondary: Color(0xFF3498DB),
          surface: Color(0xFF2A3139),
          background: Color(0xFF1A2025),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A3139),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF2A3139),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3498DB),
            side: const BorderSide(color: Color(0xFF3498DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: PermissionCheckScreen(onThemeChanged: _handleThemeChanged, currentThemeMode: _themeMode),
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const PermissionCheckScreen({super.key, required this.onThemeChanged, required this.currentThemeMode});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _isLoading = true;
  bool _showPermissionsScreen = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPermissionsScreen = prefs.getBool('hasSeenPermissionsScreen') ?? false;

    // Check all required permissions
    final permissions = [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ];

    bool allGranted = true;
    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    setState(() {
      _isLoading = false;
      // Show permissions screen if:
      // 1. User hasn't seen it before, OR
      // 2. Not all permissions are granted
      _showPermissionsScreen = !hasSeenPermissionsScreen || !allGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _showPermissionsScreen 
      ? PermissionsScreen(
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
        )
      : HomePage(
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
        );
  }
}
