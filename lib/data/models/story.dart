// data/models/story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String title;
  final String content;
  final List<String> imageUrls;
  final String authorId;
  final String? groupId;
  final List<String> tags;
  final List<String> likes;
  final int commentCount;
  final bool isFeatured;
  final String type; // Personal, Community, Success
  final String district;
  final Timestamp createdAt;
  final bool isPublished;
  final bool isVerified;

  StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.authorId,
    this.groupId,
    required this.tags,
    required this.likes,
    required this.commentCount,
    required this.isFeatured,
    required this.type,
    required this.district,
    required this.createdAt,
    required this.isPublished,
    required this.isVerified,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return StoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      authorId: data['authorId'] ?? '',
      groupId: data['groupId'],
      tags: List<String>.from(data['tags'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      type: data['type'] ?? 'Personal',
      district: data['district'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isPublished: data['isPublished'] ?? true,
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'authorId': authorId,
      'groupId': groupId,
      'tags': tags,
      'likes': likes,
      'commentCount': commentCount,
      'isFeatured': isFeatured,
      'type': type,
      'district': district,
      'createdAt': createdAt,
      'isPublished': isPublished,
      'isVerified': isVerified,
    };
  }

  StoryModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? imageUrls,
    String? authorId,
    String? groupId,
    List<String>? tags,
    List<String>? likes,
    int? commentCount,
    bool? isFeatured,
    String? type,
    String? district,
    Timestamp? createdAt,
    bool? isPublished,
    bool? isVerified,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      authorId: authorId ?? this.authorId,
      groupId: groupId ?? this.groupId,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      isFeatured: isFeatured ?? this.isFeatured,
      type: type ?? this.type,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}