import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/logo_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Simple fade animation using built-in Flutter animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    // Start animation immediately
    _controller.forward();
    
    // Use Future.microtask to ensure this runs after the build phase
    Future.microtask(() => _initializeApp());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Run auth initialization in parallel with splash display
    final authFuture = _initializeAuth();
    
    // Minimum splash display time - short for snappy feel
    await Future.delayed(const Duration(milliseconds: 600));

    // Wait for auth to complete (with its own timeout)
    await authFuture;

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigate based on auth state
    if (authProvider.isLoggedIn) {
      if (authProvider.isNurse) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.nurseDashboard);
      } else if (authProvider.isDoctor) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
      } else if (authProvider.isAdmin) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.initialize().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Auth initialization timed out - proceeding to login');
        },
      );
    } catch (e) {
      debugPrint('Auth initialization error: $e - proceeding to login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo - no complex animation
                const LogoWidget(
                  width: 280,
                  height: 100,
                ),

                const SizedBox(height: 40),

                // Hospital name
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Excellence in Healthcare',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 80),

                // Loading indicator - simple, no extra animation wrapper
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
