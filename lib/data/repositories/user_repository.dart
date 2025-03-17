// data/repositories/user_repository.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user.dart';
import '../../config/constants.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  // Create initial user document
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final newUser = UserModel(
        id: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        phone: null,
        district: '',
        bio: '',
        interests: [],
        role: AppConstants.userRole,
        groups: [],
        following: [],
        followers: [],
        isVerified: false,
        createdAt: Timestamp.now(),
        lastActive: Timestamp.now(),
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(newUser.toFirestore());
    } catch (e) {
      print('Error creating user document: $e');
      throw Exception('Failed to create user profile. Please try again.');
    }
  }
  
  // Update user's last active timestamp
  Future<void> updateUserLastActive(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently handle error as this is not critical
      print('Error updating last active: $e');
    }
  }
  
  // Upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profileImagesPath)
          .child(userId)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image. Please try again.');
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? district,
    List<String>? interests,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (district != null) updates['district'] = district;
      if (interests != null) updates['interests'] = interests;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      updates['lastActive'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile. Please try again.');
    }
  }
  
  // Follow user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Add target user to current user's following list
      final currentUserRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId);
      
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([targetUserId]),
      });
      
      // Add current user to target user's followers list
      final targetUserRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId);
      
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
      
      await batch.commit();
    } catch (e) {
      print('Error following user: $e');
      throw Exception('Failed to follow user. Please try again.');
    }
  }
  
  // Unfollow user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Remove target user from current user's following list
      final currentUserRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId);
      
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([targetUserId]),
      });
      
      // Remove current user from target user's followers list
      final targetUserRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId);
      
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
      
      await batch.commit();
    } catch (e) {
      print('Error unfollowing user: $e');
      throw Exception('Failed to unfollow user. Please try again.');
    }
  }
  
  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Search by display name or email
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
      
      // TODO: Implement more advanced search with Firebase Extensions or Cloud Functions
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
  
  // Get user's followers
  Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return [];
      
      final followers = <UserModel>[];
      
      for (final followerId in user.followers) {
        final follower = await getUserById(followerId);
        if (follower != null) {
          followers.add(follower);
        }
      }
      
      return followers;
    } catch (e) {
      print('Error getting user followers: $e');
      return [];
    }
  }
  
  // Get user's following
  Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return [];
      
      final following = <UserModel>[];
      
      for (final followingId in user.following) {
        final followingUser = await getUserById(followingId);
        if (followingUser != null) {
          following.add(followingUser);
        }
      }
      
      return following;
    } catch (e) {
      print('Error getting user following: $e');
      return [];
    }
  }
}