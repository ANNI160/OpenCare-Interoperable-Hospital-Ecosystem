/// API configuration for OpenCare backend.
/// 
/// For Android emulator: 10.0.2.2 maps to host machine's localhost.
/// For physical device via USB: run `adb reverse tcp:8000 tcp:8000`,
///   then localhost on the phone forwards to your PC's localhost.
/// For web: localhost:8000 works directly.
/// Toggle [_usePhysicalDevice] to switch between emulator and device/web.
class ApiConfig {
  // Set to true when testing on a physical device or web (uses localhost).
  // Set to false for Android emulator (uses 10.0.2.2).
  static const bool _usePhysicalDevice = true;

  static const String baseUrl = _usePhysicalDevice
      ? 'http://localhost:8000'
      : 'http://10.0.2.2:8000';

  // Auth
  static const String loginUrl = '$baseUrl/auth/login';
  static const String signupUrl = '$baseUrl/auth/signup';
  static const String meUrl = '$baseUrl/auth/me';
  static const String logoutUrl = '$baseUrl/auth/logout';

  // Patients
  static const String patientsUrl = '$baseUrl/patients';

  // Vitals
  static const String vitalsUrl = '$baseUrl/vitals';

  // Medications
  static const String medicationsUrl = '$baseUrl/medications';

  // Messages
  static const String messagesUrl = '$baseUrl/messages';

  // Tasks
  static const String tasksUrl = '$baseUrl/tasks';

  // Staff
  static const String doctorsUrl = '$baseUrl/staff/doctors';
  static const String nursesUrl = '$baseUrl/staff/nurses';
  static const String staffUrl = '$baseUrl/staff';

  // Config
  static const String configUrl = '$baseUrl/config';

  // Audit Trail
  static const String auditUrl = '$baseUrl/audit';

  // Emergencies
  static const String emergenciesUrl = '$baseUrl/emergencies';
}
