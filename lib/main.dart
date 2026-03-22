import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/message_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OpenCareApp());
}

class OpenCareApp extends StatelessWidget {
  const OpenCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'OpenCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
