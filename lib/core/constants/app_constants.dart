// lib/core/constants/app_constants.dart
import 'package:flutter/foundation.dart';

class AppConstants {
  // Emulator ke liye (Android Studio)
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api';

  // Physical device ke liye (replace with your PC's WiFi IP)
  static const String deviceBaseUrl = 'http://192.168.1.5:3000/api';

  // Production API (Render)
  static const String renderBaseUrl = 'https://mokshapp.onrender.com/api';

  // Base URL auto-select
  static String get baseUrl {
    if (kDebugMode) {
      // 👇 yaha toggle karo agar tum emulator ya physical device use kar rahe ho
      const useEmulator = true; // true = emulator, false = physical device
      return useEmulator ? emulatorBaseUrl : deviceBaseUrl;
    } else {
      return renderBaseUrl;
    }
  }

  // Socket URL (same logic)
  static String get socketUrl {
    return baseUrl.replaceAll('/api', '');
  }
}
