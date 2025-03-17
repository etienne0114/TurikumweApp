import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/post_provider.dart';
import 'data/providers/group_provider.dart';
import 'data/providers/event_provider.dart';
import 'data/providers/story_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: TurikumweApp(),
    ),
  );
}