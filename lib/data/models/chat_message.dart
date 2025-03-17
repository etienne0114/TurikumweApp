// data/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final bool isGroup;
  final String? groupId;
  final String? lastMessageText;
  final Timestamp lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.isGroup,
    this.groupId,
    this.lastMessageText,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      isGroup: data['isGroup'] ?? false,
      groupId: data['groupId'],
      lastMessageText: data['lastMessageText'],
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'isGroup': isGroup,
      'groupId': groupId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final List<String>? mediaUrls;
  final String? mediaType; // image, video, document
  final Timestamp timestamp;
  final List<String> readBy;
  final bool isEdited;
  final Map<String, dynamic>? replyTo; // References another message

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrls,
    this.mediaType,
    required this.timestamp,
    required this.readBy,
    required this.isEdited,
    this.replyTo,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      mediaUrls:
          data['mediaUrls'] != null
              ? List<String>.from(data['mediaUrls'])
              : null,
      mediaType: data['mediaType'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
      isEdited: data['isEdited'] ?? false,
      replyTo: data['replyTo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'readBy': readBy,
      'isEdited': isEdited,
      'replyTo': replyTo,
    };
  }
}
