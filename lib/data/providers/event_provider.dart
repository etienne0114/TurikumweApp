// data/providers/event_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';

class EventProvider with ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<EventModel> _events = [];
  bool _hasMoreEvents = true;
  String? _lastDocumentId;
  EventModel? _currentEvent;
  
  List<EventModel> get events => _events;
  bool get hasMoreEvents => _hasMoreEvents;
  EventModel? get currentEvent => _currentEvent;
  
  // Fetch events
  Future<List<EventModel>> fetchEvents({
    String filterType = 'upcoming',
    bool refresh = false,
    int limit = 20,
  }) async {
    if (refresh) {
      _events = [];
      _lastDocumentId = null;
      _hasMoreEvents = true;
    }
    
    if (!_hasMoreEvents && !refresh) return _events;
    
    final currentUserId = _auth.currentUser?.uid;
    
    List<EventModel> newEvents;
    
    switch (filterType) {
      case 'attending':
        if (currentUserId == null) return _events;
        newEvents = await _eventRepository.getAttendingEvents(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'myEvents':
        if (currentUserId == null) return _events;
        newEvents = await _eventRepository.getUserEvents(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'district':
        if (currentUserId == null) return _events;
        newEvents = await _eventRepository.getDistrictEvents(
          userId: currentUserId,
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'past':
        newEvents = await _eventRepository.getPastEvents(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
      case 'upcoming':
      default:
        newEvents = await _eventRepository.getUpcomingEvents(
          limit: limit,
          lastDocumentId: _lastDocumentId,
        );
        break;
    }
    
    if (newEvents.isEmpty) {
      _hasMoreEvents = false;
    } else {
      _events.addAll(newEvents);
      _lastDocumentId = newEvents.last.id;
    }
    
    notifyListeners();
    return _events;
  }
  
  // Get event by ID
  Future<EventModel?> getEventById(String eventId) async {
    final event = await _eventRepository.getEventById(eventId);
    
    if (event != null) {
      _currentEvent = event;
      notifyListeners();
    }
    
    return event;
  }
  
  // Create new event
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required String district,
    String? groupId,
    List<String>? tags,
    bool isPublic = true,
    bool isVirtual = false,
    String? virtualMeetingLink,
    File? eventImage,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    // Upload event image if provided
    String? photoUrl;
    if (eventImage != null) {
      photoUrl = await _eventRepository.uploadEventImage(eventImage);
    }
    
    // Create event in repository
    final event = await _eventRepository.createEvent(
      title: title,
      description: description,
      organizerId: userId,
      startDate: Timestamp.fromDate(startDate),
      endDate: Timestamp.fromDate(endDate),
      location: location,
      district: district,
      groupId: groupId,
      tags: tags ?? [],
      isPublic: isPublic,
      isVirtual: isVirtual,
      virtualMeetingLink: virtualMeetingLink,
      photoUrl: photoUrl,
    );
    
    // Add to local list if it matches the current filter (simplified logic)
    if (_events.isNotEmpty) {
      _events.insert(0, event);
      notifyListeners();
    }
    
    return event;
  }
  
  // RSVP to event (attend)
  Future<void> attendEvent(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _eventRepository.attendEvent(eventId: eventId, userId: userId);
    
    // Update local state
    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex >= 0) {
      final event = _events[eventIndex];
      final updatedAttendees = List<String>.from(event.attendeeIds)..add(userId);
      _events[eventIndex] = event.copyWith(attendeeIds: updatedAttendees);
    }
    
    // Also update current event if it's the one being attended
    if (_currentEvent?.id == eventId) {
      final updatedAttendees = List<String>.from(_currentEvent!.attendeeIds)..add(userId);
      _currentEvent = _currentEvent!.copyWith(attendeeIds: updatedAttendees);
    }
    
    notifyListeners();
  }
  
  // Remove RSVP from event
  Future<void> cancelAttendance(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _eventRepository.cancelAttendance(eventId: eventId, userId: userId);
    
    // Update local state
    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex >= 0) {
      final event = _events[eventIndex];
      final updatedAttendees = List<String>.from(event.attendeeIds)..remove(userId);
      _events[eventIndex] = event.copyWith(attendeeIds: updatedAttendees);
    }
    
    // Also update current event if it's the one being updated
    if (_currentEvent?.id == eventId) {
      final updatedAttendees = List<String>.from(_currentEvent!.attendeeIds)..remove(userId);
      _currentEvent = _currentEvent!.copyWith(attendeeIds: updatedAttendees);
    }
    
    notifyListeners();
  }
  
  // Update event
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? district,
    List<String>? tags,
    bool? isPublic,
    bool? isVirtual,
    String? virtualMeetingLink,
    String? status,
    File? eventImage,
  }) async {
    // Upload event image if provided
    String? photoUrl;
    if (eventImage != null) {
      photoUrl = await _eventRepository.uploadEventImage(eventImage);
    }
    
    // Update event in repository
    await _eventRepository.updateEvent(
      eventId: eventId,
      title: title,
      description: description,
      startDate: startDate != null ? Timestamp.fromDate(startDate) : null,
      endDate: endDate != null ? Timestamp.fromDate(endDate) : null,
      location: location,
      district: district,
      tags: tags,
      isPublic: isPublic,
      isVirtual: isVirtual,
      virtualMeetingLink: virtualMeetingLink,
      photoUrl: photoUrl,
      status: status,
    );
    
    // Update local state
    await getEventById(eventId);
    
    // Update in events list if present
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index >= 0 && _currentEvent != null) {
      _events[index] = _currentEvent!;
      notifyListeners();
    }
  }
  
  // Cancel event
  Future<void> cancelEvent(String eventId) async {
    await _eventRepository.updateEvent(
      eventId: eventId,
      status: 'Cancelled',
    );
    
    // Update local state
    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex >= 0) {
      _events[eventIndex] = _events[eventIndex].copyWith(status: 'Cancelled');
    }
    
    if (_currentEvent?.id == eventId) {
      _currentEvent = _currentEvent!.copyWith(status: 'Cancelled');
    }
    
    notifyListeners();
  }
  
  // Delete event
  Future<void> deleteEvent(String eventId) async {
    await _eventRepository.deleteEvent(eventId);
    
    // Remove from local list
    _events.removeWhere((event) => event.id == eventId);
    if (_currentEvent?.id == eventId) {
      _currentEvent = null;
    }
    
    notifyListeners();
  }
  
  // Get events for a group
  Future<List<EventModel>> getGroupEvents(String groupId) async {
    return await _eventRepository.getGroupEvents(groupId);
  }
  
  // Search events
  Future<List<EventModel>> searchEvents(String query) async {
    if (query.isEmpty) return [];
    
    return await _eventRepository.searchEvents(query);
  }
  
  // Clear events
  void clearEvents() {
    _events = [];
    _lastDocumentId = null;
    _hasMoreEvents = true;
    _currentEvent = null;
    notifyListeners();
  }
}