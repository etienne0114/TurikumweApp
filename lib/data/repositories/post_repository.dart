// data/repositories/post_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../../config/constants.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get posts with pagination
  Future<List<PostModel>> getPosts({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.postsCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(lastDocumentId)
            .get();
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }
  
  // Get user posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.postsCollection)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }
  
  // Get group posts
  Future<List<PostModel>> getGroupPosts(String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.postsCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting group posts: $e');
      return [];
    }
  }
  
  // Get posts from users the current user is following
  Future<List<PostModel>> getFollowingPosts({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      // First get the user to find their following list
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return [];
      
      final user = UserModel.fromFirestore(userDoc);
      
      if (user.following.isEmpty) return [];
      
      // Then query posts from those users
      Query query = _firestore
          .collection(AppConstants.postsCollection)
          .where('authorId', whereIn: user.following)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(lastDocumentId)
            .get();
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting following posts: $e');
      return [];
    }
  }
  
  // Get posts from user's district
  Future<List<PostModel>> getDistrictPosts({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      // First get the user to find their district
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return [];
      
      final user = UserModel.fromFirestore(userDoc);
      
      if (user.district.isEmpty) return [];
      
      // Then query posts from that district
      Query query = _firestore
          .collection(AppConstants.postsCollection)
          .where('location', isEqualTo: user.district)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(lastDocumentId)
            .get();
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting district posts: $e');
      return [];
    }
  }
  
  // Get featured posts
  Future<List<PostModel>> getFeaturedPosts({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.postsCollection)
          .where('isPublic', isEqualTo: true)
          .where('isPromoted', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(lastDocumentId)
            .get();
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting featured posts: $e');
      return [];
    }
  }
  
  // Upload post images
  Future<List<String>> uploadPostImages(List<dynamic> images) async {
    try {
      final imageUrls = <String>[];
      
      for (final image in images) {
        if (image is File) {
          final ref = _storage
              .ref()
              .child(AppConstants.postImagesPath)
              .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
          
          final uploadTask = await ref.putFile(image);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          
          imageUrls.add(downloadUrl);
        }
      }
      
      return imageUrls;
    } catch (e) {
      print('Error uploading post images: $e');
      throw Exception('Failed to upload images. Please try again.');
    }
  }
  
  // Create post
  Future<PostModel> createPost({
    required String authorId,
    required String content,
    List<String> imageUrls = const [],
    List<String> tags = const [],
    bool isPublic = true,
    String? location,
    String? groupId,
  }) async {
    try {
      final postRef = _firestore.collection(AppConstants.postsCollection).doc();
      
      final post = PostModel(
        id: postRef.id,
        authorId: authorId,
        groupId: groupId,
        content: content,
        imageUrls: imageUrls,
        likes: [],
        commentCount: 0,
        tags: tags,
        isPublic: isPublic,
        createdAt: Timestamp.now(),
        location: location,
        isPromoted: false,
      );
      
      await postRef.set(post.toFirestore());
      
      return post;
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post. Please try again.');
    }
  }
  
  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error liking post: $e');
      throw Exception('Failed to like post. Please try again.');
    }
  }
  
  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error unliking post: $e');
      throw Exception('Failed to unlike post. Please try again.');
    }
  }
  
  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      // Delete the post document
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .delete();
      
      // TODO: Delete comments and related data
      // TODO: Delete post images from storage
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post. Please try again.');
    }
  }
  
  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      // Basic search in content (full-text search would require Algolia or similar)
      final querySnapshot = await _firestore
          .collection(AppConstants.postsCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      // Filter in memory - not ideal for production, but works for demo
      final filteredPosts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) {
            return post.content.toLowerCase().contains(query.toLowerCase()) ||
                post.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
          })
          .toList();
      
      return filteredPosts.take(20).toList();
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }
  
  // Increment comment count
  Future<void> incrementCommentCount(String postId) async {
    try {
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing comment count: $e');
    }
  }
  
  // Decrement comment count
  Future<void> decrementCommentCount(String postId) async {
    try {
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error decrementing comment count: $e');
    }
  }
  
  // Update post
  Future<void> updatePost({
    required String postId,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    bool? isPublic,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (content != null) updates['content'] = content;
      if (imageUrls != null) updates['imageUrls'] = imageUrls;
      if (tags != null) updates['tags'] = tags;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (location != null) updates['location'] = location;
      
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update(updates);
    } catch (e) {
      print('Error updating post: $e');
      throw Exception('Failed to update post. Please try again.');
    }
  }
}