import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_page.dart';
import 'screens/permissions_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await initializeBackgroundService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto SMS Forwarder',
      theme: ThemeData(
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
      home: const PermissionCheckScreen(),
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

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

    return _showPermissionsScreen ? const PermissionsScreen() : const HomePage();
  }
}
