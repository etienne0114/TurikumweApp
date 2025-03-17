// data/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String district;
  final String bio;
  final List<String> interests;
  final String role;
  final List<String> groups;
  final List<String> following;
  final List<String> followers;
  final bool isVerified;
  final Timestamp createdAt;
  final Timestamp lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    required this.district,
    required this.bio,
    required this.interests,
    required this.role,
    required this.groups,
    required this.following,
    required this.followers,
    required this.isVerified,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      phone: data['phone'],
      district: data['district'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      role: data['role'] ?? 'user',
      groups: List<String>.from(data['groups'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActive: data['lastActive'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'district': district,
      'bio': bio,
      'interests': interests,
      'role': role,
      'groups': groups,
      'following': following,
      'followers': followers,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? district,
    String? bio,
    List<String>? interests,
    String? role,
    List<String>? groups,
    List<String>? following,
    List<String>? followers,
    bool? isVerified,
    Timestamp? createdAt,
    Timestamp? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      groups: groups ?? this.groups,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}