// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'data/providers/auth_provider.dart';
import 'presentation/screens/onboarding/splash_screen.dart';

class TurikumweApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turikumwe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
      import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'data/providers/auth_provider.dart';
import 'presentation/screens/onboarding/splash_screen.dart';

class TurikumweApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turikumwe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('rw'), // Kinyarwanda
        const Locale('fr'), // French
      ],
      home: SplashScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      navigatorObservers: [
        // Add analytics observer here
      ],
    );
  }
}  GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('rw'), // Kinyarwanda
        const Locale('fr'), // French
      ],
      home: SplashScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      navigatorObservers: [
        // Add analytics observer here
      ],
    );
  }
}