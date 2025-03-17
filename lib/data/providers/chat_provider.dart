// data/providers/chat_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  ChatModel? _currentChat;
  bool _hasMoreMessages = true;
  Timestamp? _lastMessageTimestamp;
  
  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  ChatModel? get currentChat => _currentChat;
  bool get hasMoreMessages => _hasMoreMessages;
  
  // Fetch user chats
  Future<List<ChatModel>> fetchChats({
    bool refresh = false,
    int limit = 20,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    
    if (refresh) {
      _chats = [];
    }
    
    final chats = await _chatRepository.getUserChats(userId: userId);
    
    _chats = chats;
    notifyListeners();
    
    return _chats;
  }
  
  // Get or create one-to-one chat
  Future<ChatModel> getOrCreateOneToOneChat(String otherUserId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the other user's details
    final otherUser = await _userRepository.getUserById(otherUserId);
    if (otherUser == null) {
      throw Exception('User not found');
    }
    
    // Check if chat already exists
    final existingChat = await _chatRepository.findOneToOneChat(
      userId: userId,
      otherUserId: otherUserId,
    );
    
    if (existingChat != null) {
      _currentChat = existingChat;
      _fetchMessages(existingChat.id, refresh: true);
      notifyListeners();
      return existingChat;
    }
    
    // Create new chat
    final newChat = await _chatRepository.createChat(
      participantIds: [userId, otherUserId],
      isGroup: false,
    );
    
    _currentChat = newChat;
    _messages = [];
    
    // Add to local list
    _chats.insert(0, newChat);
    notifyListeners();
    
    return newChat;
  }
  
  // Get or create group chat
  Future<ChatModel> getOrCreateGroupChat(String groupId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Check if chat already exists
    final existingChat = await _chatRepository.findGroupChat(groupId: groupId);
    
    if (existingChat != null) {
      _currentChat = existingChat;
      _fetchMessages(existingChat.id, refresh: true);
      notifyListeners();
      return existingChat;
    }
    
    // Create new chat
    final newChat = await _chatRepository.createChat(
      participantIds: [userId], // This will be populated with group members
      isGroup: true,
      groupId: groupId,
    );
    
    _currentChat = newChat;
    _messages = [];
    
    // Add to local list
    _chats.insert(0, newChat);
    notifyListeners();
    
    return newChat;
  }
  
  // Set current chat
  Future<void> setCurrentChat(String chatId) async {
    final chat = await _chatRepository.getChatById(chatId);
    
    if (chat != null) {
      _currentChat = chat;
      await _fetchMessages(chatId, refresh: true);
      
      // Mark messages as read
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _chatRepository.markChatAsRead(chatId: chatId, userId: userId);
      }
      
      notifyListeners();
    }
  }
  
  // Fetch messages for a chat
  Future<List<MessageModel>> _fetchMessages(
    String chatId, {
    bool refresh = false,
    int limit = 30,
  }) async {
    if (refresh) {
      _messages = [];
      _lastMessageTimestamp = null;
      _hasMoreMessages = true;
    }
    
    if (!_hasMoreMessages && !refresh) return _messages;
    
    final newMessages = await _chatRepository.getMessages(
      chatId: chatId,
      limit: limit,
      lastTimestamp: _lastMessageTimestamp,
    );
    
    if (newMessages.isEmpty) {
      _hasMoreMessages = false;
    } else {
      if (refresh) {
        _messages = newMessages;
      } else {
        _messages.addAll(newMessages);
      }
      
      _lastMessageTimestamp = newMessages.last.timestamp;
    }
    
    notifyListeners();
    return _messages;
  }
  
  // Load more messages
  Future<List<MessageModel>> loadMoreMessages() async {
    if (_currentChat == null || !_hasMoreMessages) return _messages;
    
    return await _fetchMessages(_currentChat!.id);
  }
  
  // Send message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String text,
    List<File>? mediaFiles,
    String? mediaType,
    Map<String, dynamic>? replyTo,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Upload media files if any
    List<String>? mediaUrls;
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      mediaUrls = await _chatRepository.uploadChatMedia(
        chatId: chatId,
        mediaFiles: mediaFiles,
      );
    }
    
    // Send message
    final message = await _chatRepository.sendMessage(
      chatId: chatId,
      senderId: userId,
      text: text,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      replyTo: replyTo,
    );
    
    // Add to local list
    _messages.insert(0, message);
    
    // Update chat in list
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex >= 0) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageText: text,
        lastMessageTime: message.timestamp,
        lastMessageSenderId: userId,
      );
    }
    
    notifyListeners();
    return message;
  }
  
  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chatRepository.deleteMessage(chatId: chatId, messageId: messageId);
    
    // Remove from local list
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }
  
  // Leave chat
  Future<void> leaveChat(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _chatRepository.leaveChat(chatId: chatId, userId: userId);
    
    // Remove from local list
    _chats.removeWhere((chat) => chat.id == chatId);
    if (_currentChat?.id == chatId) {
      _currentChat = null;
      _messages = [];
    }
    
    notifyListeners();
  }
  
  // Add participants to chat
  Future<void> addParticipantsToChat(String chatId, List<String> userIds) async {
    await _chatRepository.addParticipantsToChat(
      chatId: chatId,
      userIds: userIds,
    );
    
    // Update local state if needed
    if (_currentChat?.id == chatId) {
      final updatedChat = await _chatRepository.getChatById(chatId);
      if (updatedChat != null) {
        _currentChat = updatedChat;
        
        // Update in list if present
        final index = _chats.indexWhere((chat) => chat.id == chatId);
        if (index >= 0) {
          _chats[index] = updatedChat;
        }
        
        notifyListeners();
      }
    }
  }
  
  // Clear all data
  void clear() {
    _chats = [];
    _messages = [];
    _currentChat = null;
    _hasMoreMessages = true;
    _lastMessageTimestamp = null;
    notifyListeners();
  }
  
  // Listen to incoming messages (setup stream)
  Stream<List<MessageModel>> listenToMessages(String chatId) {
    return _chatRepository.listenToMessages(chatId);
  }
  
  // Listen to chat updates (setup stream)
  Stream<List<ChatModel>> listenToChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _chatRepository.listenToChats(userId);
  