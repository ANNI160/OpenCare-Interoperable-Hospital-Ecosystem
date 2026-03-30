class AppConstants {
  // App Info
  static const String appName = 'OpenCare';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleNurse = 'nurse';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';
  static const String rolePatient = 'patient';

  // Vitals Normal Ranges
  static const Map<String, Map<String, double>> vitalsNormalRanges = {
    'heartRate': {'min': 60, 'max': 100},
    'oxygenSaturation': {'min': 95, 'max': 100},
    'temperature': {'min': 36.1, 'max': 37.2},
    'respiratoryRate': {'min': 12, 'max': 20},
    'glucoseLevel': {'min': 70, 'max': 140},
    'systolicBP': {'min': 90, 'max': 120},
    'diastolicBP': {'min': 60, 'max': 80},
  };

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeVoice = 'voice';
  static const String messageTypeImage = 'image';

  // Patient Status
  static const String statusStable = 'stable';
  static const String statusCritical = 'critical';
  static const String statusPending = 'pending';

  // SharedPreferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefUserName = 'user_name';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefAccessToken = 'access_token';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
