// presentation/screens/events/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../data/models/event.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/event_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/dialogs.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId; // null means create new event
  
  const EventDetailScreen({
    Key? key,
    this.eventId,
  }) : super(key: key);
  
  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isCreating = false;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  DateTime _startDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _endTime = TimeOfDay(hour: 12, minute: 0);
  
  String _selectedDistrict = '';
  bool _isVirtual = false;
  String _virtualMeetingLink = '';
  bool _isPublic = true;
  
  @override
  void initState() {
    super.initState();
    _isCreating = widget.eventId == null;
    _isEditing = _isCreating;
    
    if (!_isCreating) {
      _loadEventDetails();
    } else {
      // Set default values for a new event
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        _selectedDistrict = userProvider.currentUser!.district;
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEventDetails() async {
    if (widget.eventId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final event = await eventProvider.getEventById(widget.eventId!);
      
      if (event != null) {
        // Populate form fields with event data
        _titleController.text = event.title;
        _descriptionController.text = event.description;
        _locationController.text = event.location;
        _selectedDistrict = event.district;
        _isVirtual = event.isVirtual;
        _virtualMeetingLink = event.virtualMeetingLink ?? '';
        _isPublic = event.isPublic;
        
        // Set dates and times
        _startDate = event.startDate.toDate();
        _startTime = TimeOfDay.fromDateTime(_startDate);
        _endDate = event.endDate.toDate();
        _endTime = TimeOfDay.fromDateTime(_endDate);
      }
    } catch (e) {
      print('Error loading event details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load event details')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a district')),
      );
      return;
    }
    
    if (_isVirtual && _virtualMeetingLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a virtual meeting link')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      // Combine date and time
      final startDateTime = _combineDateAndTime(_startDate, _startTime);
      final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
      if (_isCreating) {
        // Create new event
        await eventProvider.createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text,
          district: _selectedDistrict,
          isVirtual: _isVirtual,
          virtualMeetingLink: _isVirtual ? _virtualMeetingLink : null,
          isPublic: _isPublic,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context);
      } else {
        // Update existing event
        await eventProvider.updateEvent(
          eventId: widget.eventId!,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text,
          district: _selectedDistrict,
          isVirtual: _isVirtual,
          virtualMeetingLink: _isVirtual ? _virtualMeetingLink : null,
          isPublic: _isPublic,
        );
        
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event updated successfully')),
        );
      }
    } catch (e) {
      print('Error saving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _cancelEvent() async {
    if (widget.eventId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Event'),
        content: Text('Are you sure you want to cancel this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.cancelEvent(widget.eventId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event cancelled successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error cancelling event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel event')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteEvent() async {
    if (widget.eventId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.deleteEvent(widget.eventId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _toggleAttendance() async {
    if (widget.eventId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final event = eventProvider.currentEvent;
      
      if (event == null) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      final isAttending = event.attendeeIds.contains(currentUserId);
      
      if (isAttending) {
        await eventProvider.cancelAttendance(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are no longer attending this event')),
        );
      } else {
        await eventProvider.attendEvent(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are now attending this event')),
        );
      }
    } catch (e) {
      print('Error updating attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance status')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    
    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isCreating || _isEditing) {
      return _buildEditScreen();
    } else {
      return _buildViewScreen();
    }
  }
  
  Widget _buildViewScreen() {
    final eventProvider = Provider.of<EventProvider>(context);
    final event = eventProvider.currentEvent;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;
    
    if (event == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Event Details'),
        body: Center(child: Text('Event not found')),
      );
    }
    
    final isOwner = event.organizerId == currentUserId;
    final isAttending = event.attendeeIds.contains(currentUserId);
    
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: event.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: event.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: Icon(Icons.image, size: 50),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryColor,
                            child: Center(
                              child: Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                  ),
                  actions: [
                    if (isOwner)
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        // Share event
                      },
                    ),
                  ],
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event status
                        Row(
                          children: [
                            _buildEventStatusChip(event.status),
                            Spacer(),
                            if (isOwner && event.status == 'Upcoming')
                              TextButton.icon(
                                onPressed: _cancelEvent,
                                icon: Icon(Icons.cancel, color: Colors.red),
                                label: Text(
                                  'Cancel Event',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Event title
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Event date and time
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date',
                          DateFormat('EEEE, MMM dd, yyyy').format(event.startDate.toDate()),
                        ),
                        
                        SizedBox(height: 12),
                        
                        _buildInfoRow(
                          Icons.access_time,
                          'Time',
                          '${DateFormat('h:mm a').format(event.startDate.toDate())} - ${DateFormat('h:mm a').format(event.endDate.toDate())}',
                        ),
                        
                        SizedBox(height: 12),
                        
                        _buildInfoRow(
                          Icons.location_on,
                          'Location',
                          event.location,
                        ),
                        
                        if (event.isVirtual && event.virtualMeetingLink != null) ...[
                          SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.video_call,
                            'Meeting Link',
                            event.virtualMeetingLink!,
                            isLink: true,
                          ),
                        ],
                        
                        SizedBox(height: 12),
                        
                        _buildInfoRow(
                          Icons.public,
                          'Visibility',
                          event.isPublic ? 'Public' : 'Private',
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Event description
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Attendees
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attendees (${event.attendeeIds.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // View all attendees
                              },
                              child: Text('View All'),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 8),
                        
                        _buildAttendeesList(event.attendeeIds),
                        
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: event.status == 'Upcoming'
          ? Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${event.attendeeIds.length} people attending',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _toggleAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAttending
                          ? Colors.red
                          : AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      isAttending ? 'Cancel RSVP' : 'RSVP',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
  
  Widget _buildEditScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isCreating ? 'Create Event' : 'Edit Event',
        actions: [
          if (!_isCreating)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () {
                                  // Upload event image
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Event title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'Enter event title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Event description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter event description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event description';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Date and time section
                    Text(
                      'Date and Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Start date and time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartTime,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _startTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // End date and time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndTime,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _endTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Location section
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Is virtual event?
                    SwitchListTile(
                      title: Text('Virtual Event'),
                      subtitle: Text('This event will be held online'),
                      value: _isVirtual,
                      onChanged: (value) {
                        setState(() {
                          _isVirtual = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Location or virtual link
                    if (_isVirtual)
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Virtual Meeting Link',
                          hintText: 'Enter meeting URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                        initialValue: _virtualMeetingLink,
                        onChanged: (value) {
                          _virtualMeetingLink = value;
                        },
                        validator: (value) {
                          if (_isVirtual && (value == null || value.trim().isEmpty)) {
                            return 'Please enter a meeting link';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter event location',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (!_isVirtual && (value == null || value.trim().isEmpty)) {
                            return 'Please enter an event location';
                          }
                          return null;
                        },
                      ),
                    
                    SizedBox(height: 16),
                    
                    // District
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      value: _selectedDistrict.isNotEmpty ? _selectedDistrict : null,
                      hint: Text('Select district'),
                      items: [
                        'Bugesera', 'Burera', 'Gakenke', 'Gasabo', 'Gatsibo',
                        'Gicumbi', 'Gisagara', 'Huye', 'Kamonyi', 'Karongi',
                        'Kayonza', 'Kicukiro', 'Kirehe', 'Muhanga', 'Musanze',
                        'Ngoma', 'Ngororero', 'Nyabihu', 'Nyagatare', 'Nyamagabe',
                        'Nyamasheke', 'Nyanza', 'Nyarugenge', 'Nyaruguru', 'Rubavu',
                        'Ruhango', 'Rulindo', 'Rusizi', 'Rutsiro', 'Rwamagana'
                      ].map((district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a district';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Settings section
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Visibility setting
                    SwitchListTile(
                      title: Text('Public Event'),
                      subtitle: Text('Anyone can view and RSVP to this event'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isCreating ? 'Create Event' : 'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Cancel button
                    if (!_isCreating)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _loadEventDetails(); // Reset form data
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Cancel Editing'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              isLink
                  ? GestureDetector(
                      onTap: () {
                        // Open link
                      },
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildEventStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'Upcoming':
        color = Colors.blue;
        label = 'Upcoming';
        break;
      case 'Active':
        color = Colors.green;
        label = 'Happening Now';
        break;
      case 'Completed':
        color = Colors.grey;
        label = 'Completed';
        break;
      case 'Cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.blue;
        label = status;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildAttendeesList(List<String> attendeeIds) {
    if (attendeeIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No attendees yet'),
      );
    }
    
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attendeeIds.length > 5 ? 6 : attendeeIds.length,
        itemBuilder: (context, index) {
          if (index == 5) {
            // Show "more" circle
            return Container(
              margin: EdgeInsets.only(right: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+${attendeeIds.length - 5}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          
          return FutureBuilder<UserModel?>(
            future: Provider.of<UserProvider>(context, listen: false)
                .getUserById(attendeeIds[index]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                );
              }
              
              final user = snapshot.data;
              
              return Container(
                margin: EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.displayName.split(' ')[0] ?? 'User',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}