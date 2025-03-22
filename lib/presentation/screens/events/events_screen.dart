// presentation/screens/events/events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/event.dart';
import '../../../data/providers/event_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/bottom_nav.dart';
import '../../widgets/common/loaders.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _filterType = 'upcoming';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadEvents();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    
    setState(() {
      switch (_tabController.index) {
        case 0:
          _filterType = 'upcoming';
          break;
        case 1:
          _filterType = 'district';
          break;
        case 2:
          _filterType = 'attending';
          break;
        case 3:
          _filterType = 'myEvents';
          break;
      }
    });
    
    _loadEvents(refresh: true);
  }
  
  Future<void> _loadEvents({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.fetchEvents(filterType: _filterType, refresh: refresh);
    } catch (e) {
      print('Error loading events: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showCreateEventModal() {
    Navigator.pushNamed(
      context, 
      AppRoutes.eventDetail,
      arguments: null, // null means create new event
    ).then((_) => _loadEvents(refresh: true));
  }
  
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.events;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Events',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Show search UI
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadEvents(refresh: true),
                    child: events.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(events[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventModal,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        tabs: [
          Tab(text: 'Upcoming'),
          Tab(text: 'My District'),
          Tab(text: 'Attending'),
          Tab(text: 'My Events'),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message;
    
    switch (_filterType) {
      case 'upcoming':
        message = 'No upcoming events found';
        break;
      case 'district':
        message = 'No events in your district';
        break;
        case 'upcoming':
        message = 'No upcoming events found';
        break;
      case 'district':
        message = 'No events in your district';
        break;
      case 'attending':
        message = 'You\'re not attending any events';
        break;
      case 'myEvents':
        message = 'You haven\'t created any events';
        break;
      default:
        message = 'No events found';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateEventModal,
            icon: Icon(Icons.add),
            label: Text('Create Event'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventCard(EventModel event) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final isAttending = event.attendeeIds.contains(currentUserId);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context, 
            AppRoutes.eventDetail,
            arguments: event.id,
          ).then((_) => _loadEvents(refresh: true));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (event.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  event.photoUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade500,
                      ),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event date and status indicators
                  Row(
                    children: [
                      _buildEventStatusChip(event.status),
                      Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(event.startDate.toDate()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Event title
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Event location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Event time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${DateFormat('h:mm a').format(event.startDate.toDate())} - ${DateFormat('h:mm a').format(event.endDate.toDate())}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Attendees count
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${event.attendeeIds.length} attending',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Spacer(),
                      // RSVP button
                      OutlinedButton(
                        onPressed: () {
                          _toggleAttendance(event);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isAttending 
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : null,
                          side: BorderSide(
                            color: isAttending
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Text(
                          isAttending ? 'Attending' : 'RSVP',
                          style: TextStyle(
                            color: isAttending
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  void _toggleAttendance(EventModel event) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      final isAttending = event.attendeeIds.contains(currentUserId);
      
      if (isAttending) {
        await eventProvider.cancelAttendance(event.id);
      } else {
        await eventProvider.attendEvent(event.id);
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
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            _buildFilterOption('All Types', Icons.event),
            _buildFilterOption('In-Person', Icons.location_on),
            _buildFilterOption('Virtual', Icons.video_call),
            _buildFilterOption('Free Events', Icons.money_off),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Apply filters
                },
                child: Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterOption(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Spacer(),
          Checkbox(
            value: false,
            onChanged: (value) {},
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}