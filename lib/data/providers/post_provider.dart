// data/providers/post_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

class PostProvider with ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<PostModel> _posts = [];
  bool _hasMorePosts = true;
  String? _lastDocumentId;
  
  List<PostModel> get posts => _posts;
  bool get hasMorePosts => _hasMorePosts;
  
  // Fetch posts with filter
  Future<List<PostModel>> fetchPosts({
    String filterType = 'all',
    bool refresh = false,
    int limit = 20,
  }) async {
    if (refresh) {
      _posts = [];
      _lastDocumentId = null;
      _hasMorePosts = true;
    }
    
    if (!_hasMorePosts && !refresh) return _posts;
    
    final currentUserId = _auth.currentUser?.uid;
    
    List<PostModel> newPosts;
    
    switch (filterType) {
      case 'following':
        if (currentUserId == null) return _posts;
        newPosts = await _postRepository.getFollowingPosts(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'district':
        if (currentUserId == null) return _posts;
        newPosts = await _postRepository.getDistrictPosts(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'featured':
        newPosts = await _postRepository.getFeaturedPosts(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'all':
      default:
        newPosts = await _postRepository.getPosts(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
    }
    
    if (newPosts.isEmpty) {
      _hasMorePosts = false;
    } else {
      _posts.addAll(newPosts);
      _lastDocumentId = newPosts.last.id;
    }
    
    notifyListeners();
    return _posts;
  }
  
  // Fetch user posts
  Future<List<PostModel>> fetchUserPosts(String userId) async {
    return await _postRepository.getUserPosts(userId);
  }
  
  // Fetch group posts
  Future<List<PostModel>> fetchGroupPosts(String groupId) async {
    return await _postRepository.getGroupPosts(groupId);
  }
  
  // Create new post
  Future<PostModel> createPost({
    required String content,
    List<dynamic>? images,
    List<String>? tags,
    bool isPublic = true,
    String? location,
    String? groupId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    List<String> imageUrls = [];
    
    // Upload images if any
    if (images != null && images.isNotEmpty) {
      imageUrls = await _postRepository.uploadPostImages(images);
    }
    
    // Create post in repository
    final post = await _postRepository.createPost(
      authorId: userId,
      content: content,
      imageUrls: imageUrls,
      tags: tags ?? [],
      isPublic: isPublic,
      location: location,
      groupId: groupId,
    );
    
    // Add to local list if matches current filter
    // This is a simple approach - in a real app would need to check current filter
    _posts.insert(0, post);
    notifyListeners();
    
    return post;
  }
  
  // Like post
  Future<void> likePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final post = _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => throw Exception('Post not found'),
    );
    
    final isLiked = post.likes.contains(userId);
    
    if (isLiked) {
      // Unlike post
      await _postRepository.unlikePost(postId, userId);
      
      // Update local state
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex >= 0) {
        final updatedLikes = List<String>.from(post.likes)..remove(userId);
        _posts[postIndex] = post.copyWith(likes: updatedLikes);
        notifyListeners();
      }
    } else {
      // Like post
      await _postRepository.likePost(postId, userId);
      
      // Update local state
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex >= 0) {
        final updatedLikes = List<String>.from(post.likes)..add(userId);
        _posts[postIndex] = post.copyWith(likes: updatedLikes);
        notifyListeners();
      }
    }
  }
  
  // Delete post
  Future<void> deletePost(String postId) async {
    await _postRepository.deletePost(postId);
    
    // Remove from local list
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }
  
  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];
    
    return await _postRepository.searchPosts(query);
  }
  
  // Clear all posts
  void clearPosts() {
    _posts = [];
    _lastDocumentId = null;
    _hasMorePosts = true;
    notifyListeners();
  }
}