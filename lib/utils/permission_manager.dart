import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionManager {
  static const String _permissionsGrantedKey = 'permissions_granted';

  // Save whether all permissions have been granted
  static Future<void> setPermissionsGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsGrantedKey, granted);
  }

  // Check if all permissions were previously granted
  static Future<bool> werePermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsGrantedKey) ?? false;
  }

  // Check if all required permissions are currently granted
  static Future<bool> areAllPermissionsGranted() async {
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    final notificationStatus = await Permission.notification.status;

    final allGranted = smsStatus.isGranted && 
                       phoneStatus.isGranted && 
                       notificationStatus.isGranted;
    
    // Update the saved state if permissions changed
    if (allGranted != await werePermissionsGranted()) {
      await setPermissionsGranted(allGranted);
    }
    
    return allGranted;
  }
} 