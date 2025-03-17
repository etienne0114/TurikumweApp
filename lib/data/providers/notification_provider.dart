// data/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<NotificationModel> _notifications = [];
  bool _hasMoreNotifications = true;
  String? _lastDocumentId;
  int _unreadCount = 0;
  
  List<NotificationModel> get notifications => _notifications;
  bool get hasMoreNotifications => _hasMoreNotifications;
  int get unreadCount => _unreadCount;
  
  // Fetch notifications
  Future<List<NotificationModel>> fetchNotifications({
    bool refresh = false,
    int limit = 30,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    
    if (refresh) {
      _notifications = [];
      _lastDocumentId = null;
      _hasMoreNotifications = true;
    }
    
    if (!_hasMoreNotifications && !refresh) return _notifications;
    
    final newNotifications = await _notificationRepository.getNotifications(
      userId: userId,
      limit: limit,
      lastDocumentId: _lastDocumentId,
    );
    
    if (newNotifications.isEmpty) {
      _hasMoreNotifications = false;
    } else {
      _notifications.addAll(newNotifications);
      _lastDocumentId = newNotifications.last.id;
    }
    
    // Update unread count
    _updateUnreadCount();
    
    notifyListeners();
    return _notifications;
  }
  
  // Get unread count
  Future<int> getUnreadCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;
    
    _unreadCount = await _notificationRepository.getUnreadCount(userId);
    notifyListeners();
    
    return _unreadCount;
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
    
    // Update local state
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _notificationRepository.markAllAsRead(userId);
    
    // Update local state
    _notifications = _notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();
    
    _unreadCount = 0;
    notifyListeners();
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
    
    // Update local state
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    
    if (!notification.isRead) {
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    }
    
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _notificationRepository.deleteAllNotifications(userId);
    
    // Update local state
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
  
  // Create notification (for testing or admin use)
  Future<NotificationModel> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notification = await _notificationRepository.createNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data ?? {},
    );
    
    // Add to local list if it's for the current user
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == userId) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    }
    
    return notification;
  }
  
  // Listen to notifications (setup stream)
  Stream<List<NotificationModel>> listenToNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _notificationRepository.listenToNotifications(userId);
  }
  
  // Internal method to update unread count
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
  
  // Clear notifications
  void clearNotifications() {
    _notifications = [];
    _lastDocumentId = null;
    _hasMoreNotifications = true;
    _unreadCount = 0;
    notifyListeners();
  }
  
  // Generate notification object from FCM message data
  NotificationModel? parseNotificationFromFCM(Map<String, dynamic> data) {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      
      // Check if the notification is for this user
      final targetUserId = data['userId'] as String?;
      if (targetUserId != userId) return null;
      
      return NotificationModel(
        id: data['notificationId'] as String? ?? '',
        userId: userId,
        type: data['type'] as String? ?? 'General',
        title: data['title'] as String? ?? 'New Notification',
        body: data['body'] as String? ?? '',
        data: Map<String, dynamic>.from(data),
        isRead: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error parsing FCM notification: $e');
      return null;
    }
  }
  
  // Handle a new notification from FCM
  void handleNewNotification(NotificationModel notification) {
    // Add to list if not already there
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    }
  }
}