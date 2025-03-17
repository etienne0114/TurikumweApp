// data/providers/user_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _currentUser;
  Map<String, UserModel> _usersCache = {};
  
  UserModel? get currentUser => _currentUser;
  
  // Fetch current user data
  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    _currentUser = await _userRepository.getUserById(user.uid);
    notifyListeners();
    return _currentUser;
  }
  
  // Get user by ID (with caching)
  Future<UserModel?> getUserById(String userId) async {
    // Return from cache if available
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }
    
    // Fetch from repository
    final user = await _userRepository.getUserById(userId);
    
    if (user != null) {
      // Add to cache
      _usersCache[userId] = user;
    }
    
    return user;
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? district,
    List<String>? interests,
    String? phone,
    File? profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Update Firebase Auth display name if provided
    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    
    // Upload profile image if provided
    String? photoUrl;
    if (profileImage != null) {
      photoUrl = await _userRepository.uploadProfileImage(
        userId: user.uid, 
        imageFile: profileImage,
      );
      
      // Update Firebase Auth photo URL
      await user.updatePhotoURL(photoUrl);
    }
    
    // Update user document in Firestore
    await _userRepository.updateUserProfile(
      userId: user.uid,
      displayName: displayName,
      bio: bio,
      district: district,
      interests: interests,
      phone: phone,
      photoUrl: photoUrl,
    );
    
    // Refresh current user data
    await fetchCurrentUser();
  }
  
  // Follow user
  Future<void> followUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    await _userRepository.followUser(currentUserId, userId);
    
    // Update local cache
    if (_currentUser != null) {
      final following = List<String>.from(_currentUser!.following);
      following.add(userId);
      
      _currentUser = _currentUser!.copyWith(following: following);
      notifyListeners();
    }
    
    // Update other user's cache if available
    if (_usersCache.containsKey(userId)) {
      final user = _usersCache[userId]!;
      final followers = List<String>.from(user.followers);
      followers.add(currentUserId);
      
      _usersCache[userId] = user.copyWith(followers: followers);
    }
  }
  
  // Unfollow user
  Future<void> unfollowUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    await _userRepository.unfollowUser(currentUserId, userId);
    
    // Update local cache
    if (_currentUser != null) {
      final following = List<String>.from(_currentUser!.following);
      following.remove(userId);
      
      _currentUser = _currentUser!.copyWith(following: following);
      notifyListeners();
    }
    
    // Update other user's cache if available
    if (_usersCache.containsKey(userId)) {
      final user = _usersCache[userId]!;
      final followers = List<String>.from(user.followers);
      followers.remove(currentUserId);
      
      _usersCache[userId] = user.copyWith(followers: followers);
    }
  }
  
  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    return await _userRepository.searchUsers(query);
  }
  
  // Clear cache
  void clearCache() {
    _usersCache.clear();
    notifyListeners();
  }
}
