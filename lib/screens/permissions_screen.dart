import 'package:auto_sms_2/screens/home_page.dart';
import 'package:auto_sms_2/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PermissionsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const PermissionsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, bool> _permissionStatus = {
    Permission.sms: false,
    Permission.notification: false,
  };

  final Map<Permission, String> _permissionDescriptions = {
    Permission.sms: 'So you can read and forward SMS messages',
    Permission.notification: 'To keep you informed about forwarded messages',
  };

  bool _termsAccepted = false;
  bool _hasAcceptedTermsBefore = false;

  bool get _allPermissionsGranted => _permissionStatus.values.every((status) => status);
  bool get _canProceed => _allPermissionsGranted && (_termsAccepted || _hasAcceptedTermsBefore);

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('hasAcceptedTerms') ?? false;
    setState(() {
      _hasAcceptedTermsBefore = hasAccepted;
      _termsAccepted = hasAccepted;
    });
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

  Future<void> _navigateToHome() async {
    if (_canProceed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenPermissionsScreen', true);
      
      // Save terms acceptance
      if (_termsAccepted && !_hasAcceptedTermsBefore) {
        await prefs.setBool('hasAcceptedTerms', true);
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              onThemeChanged: widget.onThemeChanged,
              currentThemeMode: widget.currentThemeMode,
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    
    try {
      // On Android and iOS, we want to open the link in an external browser
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: ${e.toString()}')),
        );
      }
    }
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.sms:
        return 'SMS';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2025), // Dark background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Top icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3498DB), // Blue color for the circle
                ),
                child: const Icon(
                  Icons.security,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                "Let's get rolling!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              // Permissions list
              Expanded(
                child: ListView.builder(
                  itemCount: _permissionStatus.length,
                  itemBuilder: (context, index) {
                    final permission = _permissionStatus.keys.elementAt(index);
                    final isGranted = _permissionStatus[permission]!;
                    final description = _permissionDescriptions[permission]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isGranted ? null : () => _requestPermission(permission),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A3139),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isGranted ? Colors.green : Colors.grey[800],
                                  ),
                                  child: Icon(
                                    isGranted ? Icons.check : Icons.lock_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPermissionTitle(permission),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Terms and conditions checkbox (only show if not previously accepted)
              if (!_hasAcceptedTermsBefore)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3139),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _termsAccepted = value ?? false;
                                });
                              },
                              fillColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return const Color(0xFF3498DB);
                                  }
                                  return Colors.grey;
                                },
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'I accept the ',
                                    ),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => _launchUrl(AppUrls.termsAndConditions),
                                        child: const Text(
                                          AppStrings.termsAndConditions,
                                          style: TextStyle(
                                            color: Color(0xFF3498DB),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' and ',
                                    ),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => _launchUrl(AppUrls.privacyPolicy),
                                        child: const Text(
                                          AppStrings.privacyPolicy,
                                          style: TextStyle(
                                            color: Color(0xFF3498DB),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Bottom button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _navigateToHome : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
