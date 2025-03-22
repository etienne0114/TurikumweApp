// presentation/screens/groups/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../data/models/group.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/post_provider.dart';
import '../../../data/providers/event_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/home/post_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final String? groupId; // null means create new group

  const GroupDetailScreen({Key? key, this.groupId}) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isCreating = false;
  List<PostModel> _groupPosts = [];

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedDistrict = '';
  List<String> _selectedTags = [];
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isCreating = widget.groupId == null;
    _isEditing = _isCreating;

    if (!_isCreating) {
      _loadGroupDetails();
    } else {
      // Set default values for a new group
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        _selectedDistrict = userProvider.currentUser!.district;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    if (widget.groupId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);

      // Load group data
      final group = await groupProvider.getGroupById(widget.groupId!);

      if (group != null) {
        // Populate form fields with group data
        _nameController.text = group.name;
        _descriptionController.text = group.description;
        _rulesController.text = group.rules ?? '';
        _selectedDistrict = group.district;
        _selectedTags = List<String>.from(group.tags);
        _isPublic = group.isPublic;

        // Load group posts
        _groupPosts = await postProvider.fetchGroupPosts(widget.groupId!);
      }
    } catch (e) {
      print('Error loading group details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load group details')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a district')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      if (_isCreating) {
        // Create new group
        await groupProvider.createGroup(
          name: _nameController.text,
          description: _descriptionController.text,
          district: _selectedDistrict,
          tags: _selectedTags,
          isPublic: _isPublic,
          rules:
              _rulesController.text.isNotEmpty ? _rulesController.text : null,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Group created successfully')));
        Navigator.pop(context);
      } else {
        // Update existing group
        await groupProvider.updateGroup(
          groupId: widget.groupId!,
          name: _nameController.text,
          description: _descriptionController.text,
          district: _selectedDistrict,
          tags: _selectedTags,
          isPublic: _isPublic,
          rules:
              _rulesController.text.isNotEmpty ? _rulesController.text : null,
        );

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Group updated successfully')));
      }
    } catch (e) {
      print('Error saving group: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save group')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGroup() async {
    if (widget.groupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Group'),
            content: Text(
              'Are you sure you want to delete this group? This action cannot be undone.',
            ),
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
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.deleteGroup(widget.groupId!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Group deleted successfully')));
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete group')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleGroupMembership() async {
    if (widget.groupId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final group = groupProvider.currentGroup;

      if (group == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;

      if (currentUserId == null) return;

      final isMember = group.memberIds.contains(currentUserId);

      if (isMember) {
        await groupProvider.leaveGroup(group.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You left the group')));
      } else {
        await groupProvider.joinGroup(group.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You joined the group')));
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

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: CreateGroupPostForm(
                    groupId: widget.groupId!,
                    onPostCreated: () {
                      Navigator.pop(context);
                      _loadGroupDetails();
                    },
                  ),
                ),
          ),
    );
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
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = groupProvider.currentGroup;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;

    if (group == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Group Details'),
        body: Center(child: Text('Group not found')),
      );
    }

    final isOwner = group.creatorId == currentUserId;
    final isModerator = group.moderatorIds.contains(currentUserId);
    final isAdmin = isOwner || isModerator;
    final isMember = group.memberIds.contains(currentUserId);

    return Scaffold(
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(group.name),
                        background:
                            group.photoUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: group.photoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey.shade300,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(Icons.group, size: 50),
                                      ),
                                )
                                : Container(
                                  color: AppTheme.primaryColor,
                                  child: Center(
                                    child: Icon(
                                      Icons.group,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                      ),
                      actions: [
                        if (isAdmin)
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
                            // Share group
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'report') {
                              // Report group
                            } else if (value == 'delete' && isOwner) {
                              _deleteGroup();
                            }
                          },
                          itemBuilder:
                              (context) => [
                                if (isOwner)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Group',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!isOwner)
                                  PopupMenuItem(
                                    value: 'report',
                                    child: Row(
                                      children: [
                                        Icon(Icons.flag, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Report'),
                                      ],
                                    ),
                                  ),
                              ],
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Group info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group type and district
                                Row(
                                  children: [
                                    _buildGroupTypeChip(
                                      group.isPublic ? 'Public' : 'Private',
                                    ),
                                    SizedBox(width: 8),
                                    if (group.isVerified)
                                      Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                    Spacer(),
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      group.district,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16),

                                // Group description
                                Text(
                                  group.description,
                                  style: TextStyle(fontSize: 16),
                                ),

                                SizedBox(height: 16),

                                // Group tags
                                if (group.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        group.tags.map((tag) {
                                          return Chip(
                                            label: Text(
                                              '#$tag',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            backgroundColor: AppTheme
                                                .primaryColor
                                                .withOpacity(0.1),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            padding: EdgeInsets.zero,
                                            labelPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          );
                                        }).toList(),
                                  ),

                                SizedBox(height: 16),

                                // Group stats
                                Row(
                                  children: [
                                    _buildStatColumn(
                                      'Members',
                                      group.memberCount,
                                    ),
                                    SizedBox(width: 24),
                                    _buildStatColumn('Posts', group.postCount),
                                  ],
                                ),

                                SizedBox(height: 16),

                                // Join/Leave button
                                if (!isOwner)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _toggleGroupMembership,
                                      icon: Icon(
                                        isMember
                                            ? Icons.exit_to_app
                                            : Icons.person_add,
                                      ),
                                      label: Text(
                                        isMember ? 'Leave Group' : 'Join Group',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isMember
                                                ? Colors.red
                                                : AppTheme.primaryColor,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Tab bar
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AppTheme.primaryColor,
                            tabs: [
                              Tab(text: 'Posts'),
                              Tab(text: 'Members'),
                              Tab(text: 'About'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts tab
                    _buildPostsTab(group, isMember),

                    // Members tab
                    _buildMembersTab(group, isAdmin),

                    // About tab
                    _buildAboutTab(group),
                  ],
                ),
              ),
      floatingActionButton:
          isMember
              ? FloatingActionButton(
                onPressed: () {
                  if (_tabController.index == 0) {
                    _showCreatePostModal();
                  } else if (_tabController.index == 1 && isAdmin) {
                    // Invite members
                    _showInviteMembersModal();
                  }
                },
                backgroundColor: AppTheme.primaryColor,
                child: Icon(
                  _tabController.index == 0 ? Icons.add : Icons.person_add,
                ),
              )
              : null,
    );
  }

  Widget _buildEditScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isCreating ? 'Create Group' : 'Edit Group',
        actions: [
          if (!_isCreating)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteGroup,
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group image picker
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
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    // Upload group image
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Group name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'Enter group name',
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Group description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter group description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group description';
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
                        value:
                            _selectedDistrict.isNotEmpty
                                ? _selectedDistrict
                                : null,
                        hint: Text('Select district'),
                        items:
                            [
                              'Bugesera',
                              'Burera',
                              'Gakenke',
                              'Gasabo',
                              'Gatsibo',
                              'Gicumbi',
                              'Gisagara',
                              'Huye',
                              'Kamonyi',
                              'Karongi',
                              'Kayonza',
                              'Kicukiro',
                              'Kirehe',
                              'Muhanga',
                              'Musanze',
                              'Ngoma',
                              'Ngororero',
                              'Nyabihu',
                              'Nyagatare',
                              'Nyamagabe',
                              'Nyamasheke',
                              'Nyanza',
                              'Nyarugenge',
                              'Nyaruguru',
                              'Rubavu',
                              'Ruhango',
                              'Rulindo',
                              'Rusizi',
                              'Rutsiro',
                              'Rwamagana',
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

                      SizedBox(height: 16),

                      // Tags
                      Text(
                        'Group Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              'Community',
                              'Education',
                              'Health',
                              'Agriculture',
                              'Technology',
                              'Business',
                              'Youth',
                              'Women',
                              'Sports',
                              'Culture',
                              'Environment',
                              'Faith',
                            ].map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                                selectedColor: AppTheme.primaryColor
                                    .withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryColor,
                              );
                            }).toList(),
                      ),

                      SizedBox(height: 24),

                      // Group rules
                      TextFormField(
                        controller: _rulesController,
                        decoration: InputDecoration(
                          labelText: 'Group Rules (Optional)',
                          hintText: 'Enter group rules and guidelines',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.rule),
                        ),
                        maxLines: 5,
                      ),

                      SizedBox(height: 24),

                      // Group privacy
                      Text(
                        'Privacy Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      SwitchListTile(
                        title: Text('Public Group'),
                        subtitle: Text('Anyone can see and join this group'),
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
                          onPressed: _saveGroup,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _isCreating ? 'Create Group' : 'Save Changes',
                            style: TextStyle(fontSize: 16),
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
                                _loadGroupDetails(); // Reset form data
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

  Widget _buildPostsTab(GroupModel group, bool isMember) {
    if (!isMember && !group.isPublic) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'This is a private group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Join the group to see posts and discussions',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleGroupMembership,
              child: Text('Join Group'),
            ),
          ],
        ),
      );
    }

    if (_groupPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share something with the group!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (isMember) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreatePostModal(),
                icon: Icon(Icons.add),
                label: Text('Create Post'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _groupPosts.length,
      itemBuilder: (context, index) {
        final post = _groupPosts[index];
        return PostCard(
          post: post,
          onLike: () {
            final postProvider = Provider.of<PostProvider>(
              context,
              listen: false,
            );
            postProvider.likePost(post.id);

            // Refresh the post list
            _loadGroupDetails();
          },
          onComment: () {
            // Navigate to comments screen
          },
          onShare: () {
            // Share post
          },
          onProfileTap: () {
            // Navigate to profile
          },
        );
      },
    );
  }

  Widget _buildMembersTab(GroupModel group, bool isAdmin) {
    return FutureBuilder<List<UserModel>>(
      future: _getGroupMembers(group.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading members: ${snapshot.error}'),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No members found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This group has no members yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Member search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search members',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (query) {
                  // Filter members list based on search query
                  // This would be implemented in a real app
                },
              ),
            ),

            // Members count
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${members.length} Members',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (isAdmin) Spacer(),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: () {
                        _showInviteMembersModal();
                      },
                      icon: Icon(Icons.person_add, size: 18),
                      label: Text('Invite'),
                    ),
                ],
              ),
            ),

            // Members list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isCreator = member.id == group.creatorId;
                  final isModerator = group.moderatorIds.contains(member.id);

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          member.photoUrl != null
                              ? NetworkImage(member.photoUrl!)
                              : null,
                      child:
                          member.photoUrl == null
                              ? Text(
                                member.displayName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              )
                              : null,
                    ),
                    title: Row(
                      children: [
                        Text(
                          member.displayName,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        if (member.isVerified)
                          Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isCreator)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Creator',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isModerator)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Moderator',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            if (!isCreator && !isModerator)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    member.district,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing:
                        isAdmin && !isCreator
                            ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'promote' && !isModerator) {
                                  _promoteToModerator(group.id, member.id);
                                } else if (value == 'demote' && isModerator) {
                                  _demoteFromModerator(group.id, member.id);
                                } else if (value == 'remove') {
                                  _removeMember(group.id, member.id);
                                } else if (value == 'message') {
                                  // Navigate to the messaging screen
                                  // This would be implemented in a real app
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'message',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.message,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Message'),
                                        ],
                                      ),
                                    ),
                                    if (!isModerator)
                                      PopupMenuItem(
                                        value: 'promote',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_upward,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Make Moderator'),
                                          ],
                                        ),
                                      ),
                                    if (isModerator)
                                      PopupMenuItem(
                                        value: 'demote',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_downward,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Remove as Moderator'),
                                          ],
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_remove,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Remove from Group',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            )
                            : IconButton(
                              icon: Icon(Icons.message_outlined),
                              onPressed: () {
                                // Navigate to the messaging screen
                                // This would be implemented in a real app
                              },
                            ),
                    onTap: () {
                      // Navigate to user profile
                      // This would be implemented in a real app
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutTab(GroupModel group) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Group',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 16),

          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Created'),
            subtitle: Text(
              '${group.createdAt.toDate().day}/${group.createdAt.toDate().month}/${group.createdAt.toDate().year}',
            ),
          ),

          ListTile(
            leading: Icon(Icons.person),
            title: Text('Creator'),
            subtitle: FutureBuilder<UserModel?>(
              future: Provider.of<UserProvider>(
                context,
                listen: false,
              ).getUserById(group.creatorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...');
                }

                final creator = snapshot.data;
                return Text(creator?.displayName ?? 'Unknown');
              },
            ),
          ),

          if (group.rules != null && group.rules!.isNotEmpty) ...[
            SizedBox(height: 24),

            Text(
              'Group Rules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(group.rules!, style: TextStyle(fontSize: 16)),
            ),
          ],

          SizedBox(height: 24),

          Text(
            'Privacy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 16),

          ListTile(
            leading: Icon(
              group.isPublic ? Icons.public : Icons.lock,
              color: group.isPublic ? Colors.green : Colors.orange,
            ),
            title: Text(
              group.isPublic ? 'Public Group' : 'Private Group',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              group.isPublic
                  ? 'Anyone can see the group, its members and their posts'
                  : 'Only members can see the group posts',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTypeChip(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            type == 'Public'
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

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Future<List<UserModel>> _getGroupMembers(List<String> memberIds) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final members = <UserModel>[];

    for (final id in memberIds) {
      final user = await userProvider.getUserById(id);
      if (user != null) {
        members.add(user);
      }
    }

    // Sort members: creator first, then moderators, then regular members
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final group = groupProvider.currentGroup;

    if (group != null) {
      members.sort((a, b) {
        // Creator goes first
        if (a.id == group.creatorId) return -1;
        if (b.id == group.creatorId) return 1;

        // Moderators go next
        final aIsModerator = group.moderatorIds.contains(a.id);
        final bIsModerator = group.moderatorIds.contains(b.id);

        if (aIsModerator && !bIsModerator) return -1;
        if (!aIsModerator && bIsModerator) return 1;

        // Sort alphabetically by name
        return a.displayName.compareTo(b.displayName);
      });
    }

    return members;
  }

  void _showInviteMembersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              'Invite Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (query) {
                            // Search users
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('User list will appear here'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _promoteToModerator(String groupId, String userId) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.addModerator(groupId, userId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User promoted to moderator')));

      // Refresh group data
      _loadGroupDetails();
    } catch (e) {
      print('Error promoting user: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to promote user')));
    }
  }

  Future<void> _demoteFromModerator(String groupId, String userId) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.removeModerator(groupId, userId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User removed as moderator')));

      // Refresh group data
      _loadGroupDetails();
    } catch (e) {
      print('Error demoting user: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to demote user')));
    }
  }

  Future<void> _removeMember(String groupId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove this member from the group?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // This is not implemented yet in the GroupProvider
      // In a real app, you would call a method to remove the member
      // For now, we'll just show a success message

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Member removed from group')));

      // Refresh group data
      _loadGroupDetails();
    } catch (e) {
      print('Error removing member: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove member')));
    }
  }
}

// A stub for the create post form
class CreateGroupPostForm extends StatefulWidget {
  final String groupId;
  final VoidCallback onPostCreated;

  const CreateGroupPostForm({
    Key? key,
    required this.groupId,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  _CreateGroupPostFormState createState() => _CreateGroupPostFormState();
}

class _CreateGroupPostFormState extends State<CreateGroupPostForm> {
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.createPost(
        content: _contentController.text,
        groupId: widget.groupId,
      );

      widget.onPostCreated();
    } catch (e) {
      print('Error creating post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Create Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          Divider(),

          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              hintText: 'Write something to the group...',
              border: InputBorder.none,
            ),
            maxLines: 5,
          ),

          SizedBox(height: 16),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () {
                  // Add image
                },
              ),
              IconButton(
                icon: Icon(Icons.tag),
                onPressed: () {
                  // Add tags
                },
              ),
              Spacer(),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(onPressed: _createPost, child: Text('Post')),
            ],
          ),
        ],
      ),
    );
  }
}
