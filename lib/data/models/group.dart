// data/models/group.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? photoUrl;
  final String creatorId;
  final List<String> moderatorIds;
  final List<String> memberIds;
  final String district;
  final List<String> tags;
  final bool isPublic;
  final bool isVerified;
  final Timestamp createdAt;
  final String? rules;
  final int postCount;
  final int memberCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.creatorId,
    required this.moderatorIds,
    required this.memberIds,
    required this.district,
    required this.tags,
    required this.isPublic,
    required this.isVerified,
    required this.createdAt,
    this.rules,
    required this.postCount,
    required this.memberCount,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      creatorId: data['creatorId'] ?? '',
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      district: data['district'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isPublic: data['isPublic'] ?? true,
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      rules: data['rules'],
      postCount: data['postCount'] ?? 0,
      memberCount: data['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'creatorId': creatorId,
      'moderatorIds': moderatorIds,
      'memberIds': memberIds,
      'district': district,
      'tags': tags,
      'isPublic': isPublic,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'rules': rules,
      'postCount': postCount,
      'memberCount': memberCount,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    String? creatorId,
    List<String>? moderatorIds,
    List<String>? memberIds,
    String? district,
    List<String>? tags,
    bool? isPublic,
    bool? isVerified,
    Timestamp? createdAt,
    String? rules,
    int? postCount,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      creatorId: creatorId ?? this.creatorId,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberIds: memberIds ?? this.memberIds,
      district: district ?? this.district,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      rules: rules ?? this.rules,
      postCount: postCount ?? this.postCount,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}