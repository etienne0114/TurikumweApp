// core/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/constants.dart';

class FirebaseService {
  late FirebaseAnalytics _analytics;
  late FirebaseMessaging _messaging;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseAuth _auth;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseMessaging get messaging => _messaging;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseAuth get auth => _auth;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _messaging = FirebaseMessaging.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _auth = FirebaseAuth.instance;

    // Request notification permissions
    await _requestNotificationPermissions();
    
    // Configure Firestore
    await _configureFirestore();
    
    // Configure Analytics
    await _configureAnalytics();
    
    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  Future<void> _requestNotificationPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
    
    print('User granted permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save token to Firestore if user is logged in
    _saveTokenToFirestore(token);
    
    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }
  
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }
  
  Future<void> _configureFirestore() async {
    // Set Firestore settings
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  Future<void> _configureAnalytics() async {
    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(true);
  }
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
