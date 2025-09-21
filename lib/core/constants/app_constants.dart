import 'package:flutter/foundation.dart';

class AppConstants {
  // Local development API
  static const String localBaseUrl = 'http://10.0.2.2:3000/api';

  // Production API (Render)
  static const String renderBaseUrl = 'https://mokshapp.onrender.com/api';

  // Automatically choose based on debug/release
  static String get baseUrl => kDebugMode ? localBaseUrl : renderBaseUrl;

  // Socket URL
  static String get socketUrl =>
      kDebugMode ? 'http://10.0.2.2:3000' : 'https://mokshapp.onrender.com';
}
