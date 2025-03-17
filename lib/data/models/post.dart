/ data/models/post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String? groupId;
  final String content;
  final List<String> imageUrls;
  final List<String> likes;
  final int commentCount;
  final List<String> tags;
  final bool isPublic;
  final Timestamp createdAt;
  final String? location;
  final bool isPromoted;

  PostModel({
    required this.id,
    required this.authorId,
    this.groupId,
    required this.content,
    required this.imageUrls,
    required this.likes,
    required this.commentCount,
    required this.tags,
    required this.isPublic,
    required this.createdAt,
    this.location,
    required this.isPromoted,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      groupId: data['groupId'],
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      isPublic: data['isPublic'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      location: data['location'],
      isPromoted: data['isPromoted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'groupId': groupId,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'commentCount': commentCount,
      'tags': tags,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'location': location,
      'isPromoted': isPromoted,
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? groupId,
    String? content,
    List<String>? imageUrls,
    List<String>? likes,
    int? commentCount,
    List<String>? tags,
    bool? isPublic,
    Timestamp? createdAt,
    String? location,
    bool? isPromoted,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      isPromoted: isPromoted ?? this.isPromoted,
    );
  }