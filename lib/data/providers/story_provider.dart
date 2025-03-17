// data/providers/story_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story.dart';
import '../repositories/story_repository.dart';

class StoryProvider with ChangeNotifier {
  final StoryRepository _storyRepository = StoryRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<StoryModel> _stories = [];
  bool _hasMoreStories = true;
  String? _lastDocumentId;
  StoryModel? _currentStory;
  
  List<StoryModel> get stories => _stories;
  bool get hasMoreStories => _hasMoreStories;
  StoryModel? get currentStory => _currentStory;
  
  // Fetch stories
  Future<List<StoryModel>> fetchStories({
    String filterType = 'all',
    bool refresh = false,
    int limit = 20,
  }) async {
    if (refresh) {
      _stories = [];
      _lastDocumentId = null;
      _hasMoreStories = true;
    }
    
    if (!_hasMoreStories && !refresh) return _stories;
    
    final currentUserId = _auth.currentUser?.uid;
    
    List<StoryModel> newStories;
    
    switch (filterType) {
      case 'my':
        if (currentUserId == null) return _stories;
        newStories = await _storyRepository.getUserStories(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'district':
        if (currentUserId == null) return _stories;
        newStories = await _storyRepository.getDistrictStories(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'featured':
        newStories = await _storyRepository.getFeaturedStories(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'all':
      default:
        newStories = await _storyRepository.getStories(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
    }
    
    if (newStories.isEmpty) {
      _hasMoreStories = false;
    } else {
      _stories.addAll(newStories);
      _lastDocumentId = newStories.last.id;
    }
    
    notifyListeners();
    return _stories;
  }
  
  // Get story by ID
  Future<StoryModel?> getStoryById(String storyId) async {
    final story = await _storyRepository.getStoryById(storyId);
    
    if (story != null) {
      _currentStory = story;
      notifyListeners();
    }
    
    return story;
  }
  
  // Create new story
  Future<StoryModel> createStory({
    required String title,
    required String content,
    required String type,
    required String district,
    List<File>? images,
    List<String>? tags,
    String? groupId,
    bool isPublished = true,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Upload images if any
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      imageUrls = await _storyRepository.uploadStoryImages(images);
    }
    
    // Create story in repository
    final story = await _storyRepository.createStory(
      title: title,
      content: content,
      authorId: userId,
      imageUrls: imageUrls,
      type: type,
      district: district,
      tags: tags ?? [],
      groupId: groupId,
      isPublished: isPublished,
    );
    
    // Add to local list if published
    if (isPublished) {
      _stories.insert(0, story);
      notifyListeners();
    }
    
    return story;
  }
  
  // Update story
  Future<void> updateStory({
    required String storyId,
    String? title,
    String? content,
    String? type,
    String? district,
    List<File>? newImages,
    List<String>? existingImageUrls,
    List<String>? tags,
    String? groupId,
    bool? isPublished,
    bool? isFeatured,
  }) async {
    // Upload new images if any
    List<String>? updatedImageUrls;
    if (newImages != null && newImages.isNotEmpty) {
      final newUploadedUrls = await _storyRepository.uploadStoryImages(newImages);
      
      // Combine with existing images that weren't removed
      updatedImageUrls = [
        ...?existingImageUrls,
        ...newUploadedUrls,
      ];
    } else if (existingImageUrls != null) {
      // Only use existing images that weren't removed
      updatedImageUrls = existingImageUrls;
    }
    
    // Update story in repository
    await _storyRepository.updateStory(
      storyId: storyId,
      title: title,
      content: content,
      type: type,
      district: district,
      imageUrls: updatedImageUrls,
      tags: tags,
      groupId: groupId,
      isPublished: isPublished,
      isFeatured: isFeatured,
    );
    
    // Update local state
    await getStoryById(storyId);
    
    // Update in stories list if present
    if (_currentStory != null) {
      final index = _stories.indexWhere((story) => story.id == storyId);
      if (index >= 0) {
        _stories[index] = _currentStory!;
        notifyListeners();
      }
    }
  }
  
  // Like story
  Future<void> likeStory(String storyId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final story = _stories.firstWhere(
      (story) => story.id == storyId,
      orElse: () => throw Exception('Story not found'),
    );
    
    final isLiked = story.likes.contains(userId);
    
    if (isLiked) {
      // Unlike story
      await _storyRepository.unlikeStory(storyId, userId);
      
      // Update local state
      final storyIndex = _stories.indexWhere((story) => story.id == storyId);
      if (storyIndex >= 0) {
        final updatedLikes = List<String>.from(story.likes)..remove(userId);
        _stories[storyIndex] = story.copyWith(likes: updatedLikes);
        
        if (_currentStory?.id == storyId) {
          _currentStory = _currentStory!.copyWith(likes: updatedLikes);
        }
        
        notifyListeners();
      }
    } else {
      // Like story
      await _storyRepository.likeStory(storyId, userId);
      
      // Update local state
      final storyIndex = _stories.indexWhere((story) => story.id == storyId);
      if (storyIndex >= 0) {
        final updatedLikes = List<String>.from(story.likes)..add(userId);
        _stories[storyIndex] = story.copyWith(likes: updatedLikes);
        
        if (_currentStory?.id == storyId) {
          _currentStory = _currentStory!.copyWith(likes: updatedLikes);
        }
        
        notifyListeners();
      }
    }
  }
  
  // Delete story
  Future<void> deleteStory(String storyId) async {
    await _storyRepository.deleteStory(storyId);
    
    // Remove from local list
    _stories.removeWhere((story) => story.id == storyId);
    if (_currentStory?.id == storyId) {
      _currentStory = null;
    }
    
    notifyListeners();
  }
  
  // Search stories
  Future<List<StoryModel>> searchStories(String query) async {
    if (query.isEmpty) return [];
    
    return await _storyRepository.searchStories(query);
  }
  
  // Get group stories
  Future<List<StoryModel>> getGroupStories(String groupId) async {
    return await _storyRepository.getGroupStories(groupId);
  }
  
  // Clear stories
  void clearStories() {
    _stories = [];
    _lastDocumentId = null;
    _hasMoreStories = true;
    _currentStory = null;
    notifyListeners();
  }
}