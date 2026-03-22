import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/nurse/nurse_dashboard.dart';
import '../screens/doctor/doctor_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/patient/patient_dashboard.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String nurseDashboard = '/nurse-dashboard';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String patientDashboard = '/patient-dashboard';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    nurseDashboard: (context) => const NurseDashboard(),
    doctorDashboard: (context) => const DoctorDashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    patientDashboard: (context) => const PatientDashboard(),
  };
}
