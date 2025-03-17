// presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../data/models/post.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/post_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/bottom_nav.dart';
import '../../widgets/common/drawer.dart';
import '../../widgets/home/post_card.dart';
import '../../widgets/home/feed_filters.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _filterType = 'all'; // all, following, district
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load current user
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser();
      
      // Load posts
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.fetchPosts(filterType: _filterType);
    } catch (e) {
      print('Error loading data: $e');
      // Show error message
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onFilterChanged(String filterType) {
    setState(() {
      _filterType = filterType;
    });
    
    // Reload posts with new filter
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.fetchPosts(filterType: filterType);
  }
  
  Future<void> _refreshFeed() async {
    // Refresh posts with current filter
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.fetchPosts(filterType: _filterType, refresh: true);
  }
  
  void _showCreatePostModal() {
    // Show modal bottom sheet for creating a new post
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreatePostForm(
            onPostCreated: () {
              Navigator.pop(context);
              _refreshFeed();
            },
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final posts = postProvider.posts;
    final user = userProvider.currentUser;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Turikumwe',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications screen
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFeed,
              child: Column(
                children: [
                  // Feed filters
                  FeedFilters(
                    currentFilter: _filterType,
                    onFilterChanged: _onFilterChanged,
                    userDistrict: user?.district ?? '',
                  ),
                  
                  // Post list
                  Expanded(
                    child: posts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return PostCard(
                                post: post,
                                onLike: () {
                                  postProvider.likePost(post.id);
                                },
                                onComment: () {
                                  // Navigate to post detail/comments
                                },
                                onShare: () {
                                  // Share post
                                },
                                onProfileTap: () {
                                  // Navigate to profile
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feed_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts to show',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _filterType == 'all'
                ? 'Be the first to share something with the community!'
                : _filterType == 'following'
                    ? 'Follow people to see their posts here'
                    : 'No posts from your district yet. Share something!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreatePostModal,
            icon: Icon(Icons.add),
            label: Text('Create Post'),
          ),
        ],
      ),
    );
  }
}

// Creating a stub for the CreatePostForm
class CreatePostForm extends StatefulWidget {
  final VoidCallback onPostCreated;
  
  const CreatePostForm({
    Key? key,
    required this.onPostCreated,
  }) : super(key: key);
  
  @override
  _CreatePostFormState createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  List<String> _selectedTags = [];
  bool _isPublic = true;
  bool _isLoading = false;
  List<dynamic> _selectedImages = [];
  String? _location;
  String? _selectedGroup;
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImages() async {
    // Image picking functionality
  }
  
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.createPost(
        content: _contentController.text.trim(),
        images: _selectedImages,
        tags: _selectedTags,
        isPublic: _isPublic,
        location: _location,
        groupId: _selectedGroup,
      );
      
      widget.onPostCreated();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post. Please try again.')),
      );
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Post',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // Post content field
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What would you like to share?',
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter some content';
                }
                return null;
              },
            ),
            
            // Selected images preview
            if (_selectedImages.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImages,
                ),
                IconButton(
                  icon: Icon(Icons.location_on_outlined),
                  onPressed: () {
                    // Add location
                  },
                ),
                IconButton(
                  icon: Icon(Icons.tag),
                  onPressed: () {
                    // Add tags
                  },
                ),
                IconButton(
                  icon: Icon(Icons.group_outlined),
                  onPressed: () {
                    // Select group
                  },
                ),
                Spacer(),
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                Text(_isPublic ? 'Public' : 'Private'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Submit button
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}