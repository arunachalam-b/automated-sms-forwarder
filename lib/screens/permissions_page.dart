import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';
import '../utils/permission_manager.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _smsPermissionGranted = false;
  bool _phonePermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _smsPermissionGranted = smsStatus.isGranted;
      _phonePermissionGranted = phoneStatus.isGranted;
      _notificationPermissionGranted = notificationStatus.isGranted;
      _isCheckingPermissions = false;
    });

    _checkAllPermissionsGranted();
  }

  void _checkAllPermissionsGranted() {
    if (_smsPermissionGranted && _phonePermissionGranted && _notificationPermissionGranted) {
      // All permissions granted, save this state and navigate to home
      PermissionManager.setPermissionsGranted(true);
      _navigateToHome();
    }
  }

  Future<void> _requestPermission(Permission permission, String permissionName) async {
    final status = await permission.request();
    
    setState(() {
      switch (permission) {
        case Permission.sms:
          _smsPermissionGranted = status.isGranted;
          break;
        case Permission.phone:
          _phonePermissionGranted = status.isGranted;
          break;
        case Permission.notification:
          _notificationPermissionGranted = status.isGranted;
          break;
        default:
          break;
      }
    });

    _checkAllPermissionsGranted();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto SMS Forwarder requires the following permissions to work properly:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildPermissionItem(
              'SMS Permission',
              'Required to read and forward incoming SMS messages',
              _smsPermissionGranted,
              () => _requestPermission(Permission.sms, 'SMS'),
            ),
            const Divider(),
            _buildPermissionItem(
              'Phone Permission',
              'Required to access telephony state',
              _phonePermissionGranted,
              () => _requestPermission(Permission.phone, 'Phone'),
            ),
            const Divider(),
            _buildPermissionItem(
              'Notification Permission',
              'Required for notification when service is running',
              _notificationPermissionGranted,
              () => _requestPermission(Permission.notification, 'Notification'),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _smsPermissionGranted && _phonePermissionGranted && _notificationPermissionGranted
                    ? _navigateToHome
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    String title,
    String description,
    bool isGranted,
    VoidCallback onRequestPermission,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            ElevatedButton(
              onPressed: onRequestPermission,
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }
} 