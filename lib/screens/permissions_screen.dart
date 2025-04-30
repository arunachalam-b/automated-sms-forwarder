import 'package:auto_sms_2/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, bool> _permissionStatus = {
    Permission.sms: false,
    Permission.phone: false,
    Permission.notification: false,
  };

  final Map<Permission, String> _permissionDescriptions = {
    Permission.sms: 'We need SMS permission to read incoming messages and forward them based on your filters.',
    Permission.phone: 'Phone permission is required to check the device state and ensure proper SMS handling.',
    Permission.notification: 'Notification permission is needed to show you when messages are forwarded and keep the service running in the background.',
  };

  bool get _allPermissionsGranted => _permissionStatus.values.every((status) => status);

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (var permission in _permissionStatus.keys) {
      final status = await permission.status;
      setState(() {
        _permissionStatus[permission] = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      _permissionStatus[permission] = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto SMS Forwarder needs the following permissions to function properly:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _permissionStatus.length,
                itemBuilder: (context, index) {
                  final permission = _permissionStatus.keys.elementAt(index);
                  final isGranted = _permissionStatus[permission]!;
                  final description = _permissionDescriptions[permission]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isGranted ? Icons.check_circle : Icons.error_outline,
                                color: isGranted ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  permission.toString().split('.').last,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(description),
                          const SizedBox(height: 12),
                          if (!isGranted)
                            ElevatedButton(
                              onPressed: () => _requestPermission(permission),
                              child: const Text('Grant Permission'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_allPermissionsGranted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  child: const Text('Continue to App'),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 