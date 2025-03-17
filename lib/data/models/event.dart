// data/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? photoUrl;
  final String organizerId;
  final String? groupId;
  final Timestamp startDate;
  final Timestamp endDate;
  final String location;
  final String district;
  final List<String> attendeeIds;
  final List<String> tags;
  final bool isPublic;
  final bool isVirtual;
  final String? virtualMeetingLink;
  final Timestamp createdAt;
  final String status; // Upcoming, Active, Completed, Cancelled

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.photoUrl,
    required this.organizerId,
    this.groupId,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.district,
    required this.attendeeIds,
    required this.tags,
    required this.isPublic,
    required this.isVirtual,
    this.virtualMeetingLink,
    required this.createdAt,
    required this.status,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      organizerId: data['organizerId'] ?? '',
      groupId: data['groupId'],
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      location: data['location'] ?? '',
      district: data['district'] ?? '',
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isPublic: data['isPublic'] ?? true,
      isVirtual: data['isVirtual'] ?? false,
      virtualMeetingLink: data['virtualMeetingLink'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'Upcoming',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'organizerId': organizerId,
      'groupId': groupId,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'district': district,
      'attendeeIds': attendeeIds,
      'tags': tags,
      'isPublic': isPublic,
      'isVirtual': isVirtual,
      'virtualMeetingLink': virtualMeetingLink,
      'createdAt': createdAt,
      'status': status,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? photoUrl,
    String? organizerId,
    String? groupId,
    Timestamp? startDate,
    Timestamp? endDate,
    String? location,
    String? district,
    List<String>? attendeeIds,
    List<String>? tags,
    bool? isPublic,
    bool? isVirtual,
    String? virtualMeetingLink,
    Timestamp? createdAt,
    String? status,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      organizerId: organizerId ?? this.organizerId,
      groupId: groupId ?? this.groupId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      district: district ?? this.district,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      isVirtual: isVirtual ?? this.isVirtual,
      virtualMeetingLink: virtualMeetingLink ?? this.virtualMeetingLink,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}