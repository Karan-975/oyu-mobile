import 'package:flutter/foundation.dart';

// API Configuration
class ApiConfig {
  static const String _baseUrlOverride = String.fromEnvironment('OYU_API_BASE_URL');

  // Android emulator cannot reach host localhost directly, so use 10.0.2.2 by default.
  // Override with --dart-define=OYU_API_BASE_URL=http://your-host:5000/api when needed.
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000/api';
    }
  }
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  static const String updateProfileEndpoint = '/auth/me';
  
  // Borehole endpoints
  static const String boreholesEndpoint = '/boreholes';
  
  // Survey endpoints
  static const String surveysEndpoint = '/surveys';
  static const String submitSurveyEndpoint = '/surveys';
  
  // Grievance endpoints
  static const String grievancesEndpoint = '/grievances';

  // Rehabilitation endpoints
  static const String rehabilitationEndpoint = '/rehabilitation';

  // Water testing endpoints
  static const String waterTestingEndpoint = '/water-testing';
  
  // Form endpoints
  static const String formsEndpoint = '/forms/modules';
  
  // File upload
  static const String uploadFileEndpoint = '/files';
  
  // Notification / FCM endpoints
  static const String fcmTokenEndpoint = '/notifications/fcm-token';
  
  // Request timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
