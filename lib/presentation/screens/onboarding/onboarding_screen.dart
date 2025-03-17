// presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Welcome to Turikumwe',
      description: 'Connect with Rwandans from all districts and backgrounds to build a stronger community together.',
      animation: 'assets/animations/community_welcome.json',
    ),
    OnboardingContent(
      title: 'Join Local Groups',
      description: 'Find and join groups focused on community development, cultural exchange, and social support.',
      animation: 'assets/animations/groups_collaboration.json',
    ),
    OnboardingContent(
      title: 'Share Your Story',
      description: 'Share your experiences and success stories to inspire others and celebrate unity.',
      animation: 'assets/animations/storytelling.json',
    ),
    OnboardingContent(
      title: 'Discover Events',
      description: 'Stay updated on community events and gatherings happening near you.',
      animation: 'assets/animations/events_calendar.json',
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
    
    // Navigate to login screen
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _contents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final content = _contents[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animation
                        Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Lottie.asset(
                            content.animation,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          content.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          content.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _contents.length,
                  (index) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage == 0
                      ? const SizedBox(width: 80)
                      : TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  
                  // Next/Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _contents.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                    ),
                    child: Text(
                      _currentPage == _contents.length - 1 ? 'Get Started' : 'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String animation;
  
  OnboardingContent({
    required this.title,
    required this.description,
    required this.animation,
  });
}