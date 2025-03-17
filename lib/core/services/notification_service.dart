// core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/constants.dart';
import '../../data/models/notification.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late FlutterLocalNotificationsPlugin _localNotifications;
  
  Future<void> initialize() async {
    // Initialize local notifications
    _localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configure notification taps when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Show local notification
      await _showLocalNotification(
        message.notification?.title ?? 'Turikumwe',
        message.notification?.body ?? '',
        message.data,
      );
      
      // Store notification in Firestore
      await _storeNotificationInFirestore(
        message.notification?.title ?? 'Turikumwe',
        message.notification?.body ?? '',
        message.data,
      );
    }
  }
  
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped in background!');
    print('Message data: ${message.data}');
    
    // Mark notification as read in Firestore
    if (message.data['notificationId'] != null) {
      await _markNotificationAsRead(message.data['notificationId']);
    }
    
    // Handle navigation based on notification type
    // This would be expanded to properly route to the right screen
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Parse the notification payload
    final String? payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      
      // Handle navigation based on notification type
      // This would be expanded to properly route to the right screen
    }
  }
  
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'turikumwe_channel_id',
      'Turikumwe Notifications',
      channelDescription: 'Notifications from Turikumwe app',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _localNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: data.toString(),
    );
  }
  
  Future<void> _storeNotificationInFirestore(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final type = data['type'] ?? 'General';
    
    final notification = NotificationModel(
      id: '',
      userId: currentUser.uid,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: Timestamp.now(),
    );
    
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add(notification.toFirestore());
  }
  
  Future<void> _markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
  
  Future<void> markAllNotificationsAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final batch = _firestore.batch();
    
    final querySnapshot = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
  
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    // Store notification in Firestore
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: Timestamp.now(),
    );
    
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add(notification.toFirestore());
    
    // Note: To actually send push notifications, you would need a server
    // component that can send FCM messages. This method only stores the 
    // notification in Firestore for in-app notification display.
  }
}