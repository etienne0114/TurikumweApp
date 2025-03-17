// presentation/screens/onboarding/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animationController.forward();
    
    // Navigate to the appropriate screen after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkFirstTimeAndNavigate();
      }
    });
  }
  
  Future<void> _checkFirstTimeAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      // No user logged in
      if (onboardingCompleted) {
        // Not first time - go to login
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        // First time - go to onboarding
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    } else {
      // User is logged in - go to home
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Animation
            Container(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/community_connection.json',
                controller: _animationController,
                onLoaded: (composition) {
                  _animationController.duration = composition.duration;
                  _animationController.forward();
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // App Name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tagline
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}