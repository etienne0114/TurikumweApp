// presentation/screens/groups/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/group.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/bottom_nav.dart';
import '../../widgets/common/loaders.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _filterType = 'all';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadGroups();
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
          _filterType = 'all';
          break;
        case 1:
          _filterType = 'my';
          break;
        case 2:
          _filterType = 'district';
          break;
      }
    });
    
    _loadGroups(refresh: true);
  }
  
  Future<void> _loadGroups({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.fetchGroups(filterType: _filterType, refresh: refresh);
    } catch (e) {
      print('Error loading groups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showCreateGroupModal() {
    Navigator.pushNamed(
      context, 
      AppRoutes.groupDetail,
      arguments: null, // null means create new group
    ).then((_) => _loadGroups(refresh: true));
  }
  
  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Groups',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Show search UI
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
                    onRefresh: () => _loadGroups(refresh: true),
                    child: groups.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              return _buildGroupCard(groups[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupModal,
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
          Tab(text: 'All Groups'),
          Tab(text: 'My Groups'),
          Tab(text: 'My District'),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message;
    
    switch (_filterType) {
      case 'all':
        message = 'No groups found';
        break;
      case 'my':
        message = 'You\'re not a member of any groups';
        break;
      case 'district':
        message = 'No groups in your district';
        break;
      default:
        message = 'No groups found';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
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
            onPressed: _showCreateGroupModal,
            icon: Icon(Icons.add),
            label: Text('Create Group'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupCard(GroupModel group) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final isMember = group.memberIds.contains(currentUserId);
    
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
            AppRoutes.groupDetail,
            arguments: group.id,
          ).then((_) => _loadGroups(refresh: true));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Image
            if (group.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: group.photoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group type and verification
                  Row(
                    children: [
                      _buildGroupTypeChip(group.isPublic ? 'Public' : 'Private'),
                      SizedBox(width: 8),
                      if (group.isVerified)
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      Spacer(),
                      Text(
                        group.district,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Group name
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Group description
                  Text(
                    group.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Group stats
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${group.memberCount} members',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.post_add,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${group.postCount} posts',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          _toggleGroupMembership(group);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isMember
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : null,
                          side: BorderSide(
                            color: isMember
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        child: Text(
                          isMember ? 'Joined' : 'Join',
                          style: TextStyle(
                            color: isMember
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
  
  Widget _buildGroupTypeChip(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type == 'Public'
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: type == 'Public' ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  void _toggleGroupMembership(GroupModel group) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      final isMember = group.memberIds.contains(currentUserId);
      
      if (isMember) {
        await groupProvider.leaveGroup(group.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You left the group')),
        );
      } else {
        await groupProvider.joinGroup(group.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You joined the group')),
        );
      }
    } catch (e) {
      print('Error updating group membership: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group membership')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
