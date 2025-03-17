// data/providers/group_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../repositories/group_repository.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _groupRepository = GroupRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<GroupModel> _groups = [];
  bool _hasMoreGroups = true;
  String? _lastDocumentId;
  GroupModel? _currentGroup;
  
  List<GroupModel> get groups => _groups;
  bool get hasMoreGroups => _hasMoreGroups;
  GroupModel? get currentGroup => _currentGroup;
  
  // Fetch groups
  Future<List<GroupModel>> fetchGroups({
    String filterType = 'all',
    bool refresh = false,
    int limit = 20,
  }) async {
    if (refresh) {
      _groups = [];
      _lastDocumentId = null;
      _hasMoreGroups = true;
    }
    
    if (!_hasMoreGroups && !refresh) return _groups;
    
    final currentUserId = _auth.currentUser?.uid;
    
    List<GroupModel> newGroups;
    
    switch (filterType) {
      case 'my':
        if (currentUserId == null) return _groups;
        newGroups = await _groupRepository.getUserGroups(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'district':
        if (currentUserId == null) return _groups;
        newGroups = await _groupRepository.getDistrictGroups(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'featured':
        newGroups = await _groupRepository.getFeaturedGroups(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'all':
      default:
        newGroups = await _groupRepository.getGroups(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
    }
    
    if (newGroups.isEmpty) {
      _hasMoreGroups = false;
    } else {
      _groups.addAll(newGroups);
      _lastDocumentId = newGroups.last.id;
    }
    
    notifyListeners();
    return _groups;
  }
  
  // Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    final group = await _groupRepository.getGroupById(groupId);
    
    if (group != null) {
      _currentGroup = group;
      notifyListeners();
    }
    
    return group;
  }
  
  // Create new group
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String district,
    List<String>? tags,
    bool isPublic = true,
    File? groupImage,
    String? rules,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Upload group image if provided
    String? photoUrl;
    if (groupImage != null) {
      photoUrl = await _groupRepository.uploadGroupImage(groupImage);
    }
    
    // Create group in repository
    final group = await _groupRepository.createGroup(
      name: name,
      description: description,
      creatorId: userId,
      district: district,
      tags: tags ?? [],
      isPublic: isPublic,
      photoUrl: photoUrl,
      rules: rules,
    );
    
    // Add to local list
    _groups.insert(0, group);
    notifyListeners();
    
    return group;
  }
  
  // Join group
  Future<void> joinGroup(String groupId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _groupRepository.joinGroup(groupId: groupId, userId: userId);
    
    // Update local state
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex >= 0) {
      final group = _groups[groupIndex];
      final updatedMembers = List<String>.from(group.memberIds)..add(userId);
      _groups[groupIndex] = group.copyWith(
        memberIds: updatedMembers,
        memberCount: group.memberCount + 1,
      );
    }
    
    // Also update current group if it's the one being joined
    if (_currentGroup?.id == groupId) {
      final updatedMembers = List<String>.from(_currentGroup!.memberIds)..add(userId);
      _currentGroup = _currentGroup!.copyWith(
        memberIds: updatedMembers,
        memberCount: _currentGroup!.memberCount + 1,
      );
    }
    
    notifyListeners();
  }
  
  // Leave group
  Future<void> leaveGroup(String groupId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _groupRepository.leaveGroup(groupId: groupId, userId: userId);
    
    // Update local state
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex >= 0) {
      final group = _groups[groupIndex];
      final updatedMembers = List<String>.from(group.memberIds)..remove(userId);
      _groups[groupIndex] = group.copyWith(
        memberIds: updatedMembers,
        memberCount: group.memberCount - 1,
      );
    }
    
    // Also update current group if it's the one being left
    if (_currentGroup?.id == groupId) {
      final updatedMembers = List<String>.from(_currentGroup!.memberIds)..remove(userId);
      _currentGroup = _currentGroup!.copyWith(
        memberIds: updatedMembers,
        memberCount: _currentGroup!.memberCount - 1,
      );
    }
    
    notifyListeners();
  }
  
  // Update group
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? district,
    List<String>? tags,
    bool? isPublic,
    File? groupImage,
    String? rules,
  }) async {
    // Upload group image if provided
    String? photoUrl;
    if (groupImage != null) {
      photoUrl = await _groupRepository.uploadGroupImage(groupImage);
    }
    
    // Update group in repository
    await _groupRepository.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
      district: district,
      tags: tags,
      isPublic: isPublic,
      photoUrl: photoUrl,
      rules: rules,
    );
    
    // Update local state
    await getGroupById(groupId);
    
    // Update in groups list if present
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index >= 0 && _currentGroup != null) {
      _groups[index] = _currentGroup!;
      notifyListeners();
    }
  }
  
  // Delete group
  Future<void> deleteGroup(String groupId) async {
    await _groupRepository.deleteGroup(groupId);
    
    // Remove from local list
    _groups.removeWhere((group) => group.id == groupId);
    if (_currentGroup?.id == groupId) {
      _currentGroup = null;
    }
    
    notifyListeners();
  }
  
  // Add moderator to group
  Future<void> addModerator(String groupId, String userId) async {
    await _groupRepository.addModerator(groupId: groupId, userId: userId);
    
    // Update local state if needed
    await getGroupById(groupId);
  }
  
  // Remove moderator from group
  Future<void> removeModerator(String groupId, String userId) async {
    await _groupRepository.removeModerator(groupId: groupId, userId: userId);
    
    // Update local state if needed
    await getGroupById(groupId);
  }
  
  // Search groups
  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.isEmpty) return [];
    
    return await _groupRepository.searchGroups(query);
  }
  
  // Clear groups
  void clearGroups() {
    _groups = [];
    _lastDocumentId = null;
    _hasMoreGroups = true;
    _currentGroup = null;
    notifyListeners();
  }
}