// presentation/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/post_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/loaders.dart';
import '../../widgets/home/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isCurrentUser = false;
  bool _isFollowing = false;
  UserModel? _user;
  List<PostModel> _posts = [];
  File? _newProfileImage;
  bool _isEditingProfile = false;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  String _selectedDistrict = '';
  List<String> _selectedInterests = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      
      // Check if viewing current user's profile
      final currentUserId = authProvider.currentUser?.uid;
      final userId = widget.userId ?? currentUserId;
      
      if (userId == null) {
        // No user logged in
        Navigator.pop(context);
        return;
      }
      
      _isCurrentUser = userId == currentUserId;
      
      // Load user data
      final user = await userProvider.getUserById(userId);
      
      if (user == null) {
        // User not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
        Navigator.pop(context);
        return;
      }
      
      // Check if current user is following this user
      if (!_isCurrentUser && currentUserId != null) {
        final currentUser = await userProvider.getUserById(currentUserId);
        _isFollowing = currentUser?.following.contains(userId) ?? false;
      }
      
      // Load user's posts
      final posts = await postProvider.fetchUserPosts(userId);
      
      setState(() {
        _user = user;
        _posts = posts;
        
        // Initialize form controllers if this is the current user
        if (_isCurrentUser) {
          _displayNameController.text = user.displayName;
          _bioController.text = user.bio;
          _phoneController.text = user.phone ?? '';
          _selectedDistrict = user.district;
          _selectedInterests = List<String>.from(user.interests);
        }
      });
    } catch (e) {
      print('Error loading profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _followUser() async {
    if (_user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (_isFollowing) {
        // Unfollow user
        await userProvider.unfollowUser(_user!.id);
      } else {
        // Follow user
        await userProvider.followUser(_user!.id);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print('Error following/unfollowing user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating follow status')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _newProfileImage = File(image.path);
      });
    }
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      
      // Reset form values if canceling edit
      if (!_isEditingProfile && _user != null) {
        _displayNameController.text = _user!.displayName;
        _bioController.text = _user!.bio;
        _phoneController.text = _user!.phone ?? '';
        _selectedDistrict = _user!.district;
        _selectedInterests = List<String>.from(_user!.interests);
        _newProfileImage = null;
      }
    });
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select your district')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await userProvider.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        district: _selectedDistrict,
        interests: _selectedInterests,
        phone: _phoneController.text.trim(),
        profileImage: _newProfileImage,
      );
      
      // Reload user data
      final updatedUser = await userProvider.fetchCurrentUser();
      
      setState(() {
        _user = updatedUser;
        _isEditingProfile = false;
        _newProfileImage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isCurrentUser ? 'My Profile' : 'Profile',
        actions: _isCurrentUser
            ? [
                IconButton(
                  icon: Icon(
                    _isEditingProfile ? Icons.close : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: _toggleEditMode,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('User not found'))
              : _isEditingProfile
                  ? _buildEditProfileForm()
                  : _buildProfileContent(),
    );
  }
  
  Widget _buildProfileContent() {
    if (_user == null) return SizedBox();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'About'),
              Tab(text: 'Groups'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts tab
                _posts.isEmpty
                    ? Center(
                        child: Text('No posts yet'),
                      )
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return PostCard(
                            post: post,
                            onLike: () {
                              // Like post
                              final postProvider = Provider.of<PostProvider>(
                                context, 
                                listen: false,
                              );
                              postProvider.likePost(post.id);
                            },
                            onComment: () {
                              // Navigate to comments
                            },
                            onShare: () {
                              // Share post
                            },
                            onProfileTap: () {
                              // Already on profile page
                            },
                          );
                        },
                      ),
                
                // About tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(_user!.bio.isEmpty ? 'No bio added yet' : _user!.bio),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        'District',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(_user!.district.isEmpty ? 'Not specified' : _user!.district),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        'Interests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      _user!.interests.isEmpty
                          ? Text('No interests added yet')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _user!.interests.map((interest) {
                                return Chip(
                                  label: Text(interest),
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                                );
                              }).toList(),
                            ),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        'Member Since',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_user!.createdAt.toDate().day}/${_user!.createdAt.toDate().month}/${_user!.createdAt.toDate().year}',
                      ),
                    ],
                  ),
                ),
                
                // Groups tab
                _user!.groups.isEmpty
                    ? Center(
                        child: Text('Not a member of any groups yet'),
                      )
                    : Center(
                        child: Text('Groups list will be implemented here'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    if (_user == null) return SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _user!.photoUrl != null
                ? CachedNetworkImageProvider(_user!.photoUrl!)
                : null,
            child: _user!.photoUrl == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey.shade600,
                  )
                : null,
          ),
          
          SizedBox(height: 16),
          
          // User name and verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _user!.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_user!.isVerified)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 4),
          
          // User role badge
          if (_user!.role != AppConstants.userRole)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _user!.role == AppConstants.adminRole
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _user!.role == AppConstants.adminRole ? 'Admin' : 'Moderator',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _user!.role == AppConstants.adminRole
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ),
          
          SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('Posts', _posts.length),
              Container(
                height: 30,
                child: VerticalDivider(
                  color: Colors.grey.shade300,
                  width: 30,
                  thickness: 1,
                ),
              ),
              _buildStatColumn('Followers', _user!.followers.length),
              Container(
                height: 30,
                child: VerticalDivider(
                  color: Colors.grey.shade300,
                  width: 30,
                  thickness: 1,
                ),
              ),
              _buildStatColumn('Following', _user!.following.length),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Action buttons
          if (!_isCurrentUser)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Follow/Unfollow button
                ElevatedButton(
                  onPressed: _followUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? Colors.grey.shade200
                        : AppTheme.primaryColor,
                    foregroundColor: _isFollowing
                        ? AppTheme.primaryColor
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                ),
                
                SizedBox(width: 8),
                
                // Message button
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to message screen
                  },
                  icon: Icon(Icons.message_outlined),
                  label: Text('Message'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditProfileForm() {
    if (_user == null) return SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : (_user!.photoUrl != null
                            ? CachedNetworkImageProvider(_user!.photoUrl!)
                            : null) as ImageProvider?,
                    child: _newProfileImage == null && _user!.photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                  
                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: _pickImage,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Display name
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Phone number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            
            SizedBox(height: 16),
            
            // District dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'District',
                hintText: 'Select your district',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              value: _selectedDistrict.isNotEmpty ? _selectedDistrict : null,
              items: AppConstants.rwandaDistricts.map((district) {
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
            ),
            
            SizedBox(height: 16),
            
            // Bio
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us a bit about yourself',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a short bio';
                }
                return null;
              },
            ),
            
            SizedBox(height: 24),
            
            // Interests
            Text(
              'Select Your Interests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Community Development',
                'Education',
                'Healthcare',
                'Agriculture',
                'Technology',
                'Arts & Culture',
                'Sports',
                'Environment',
                'Business',
                'Youth Empowerment',
                'Women Empowerment',
                'Social Justice',
              ].map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            
            SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleEditMode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}