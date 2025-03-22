// presentation/screens/messages/chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/bottom_nav.dart';

class ChatsListScreen extends StatefulWidget {
  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadChats();
  }
  
  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.fetchChats(refresh: true);
    } catch (e) {
      print('Error loading chats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chats')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showNewChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NewChatSheet(
            onUserSelected: (userId) {
              Navigator.pop(context);
              _startNewChat(userId);
            },
          ),
        ),
      ),
    );
  }
  
  Future<void> _startNewChat(String userId) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await chatProvider.getOrCreateOneToOneChat(userId);
      
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetail,
        arguments: {
          'chatId': chat.id,
          'isGroup': false,
        },
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final chats = chatProvider.chats;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Messages',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChats,
              child: chats.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        return _buildChatItem(chats[index]);
                      },
                    ),
            ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatModal,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.chat),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewChatModal,
            icon: Icon(Icons.chat),
            label: Text('New Message'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatItem(ChatModel chat) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;
    
    if (currentUserId == null) return SizedBox.shrink();
    
    // For one-to-one chats, we need to show the other person's info
    String? otherUserId;
    if (!chat.isGroup) {
      final otherParticipants = chat.participantIds.where((id) => id != currentUserId).toList();
      if (otherParticipants.isNotEmpty) {
        otherUserId = otherParticipants.first;
      }
    }
    
    return FutureBuilder<UserModel?>(
      future: otherUserId != null
          ? Provider.of<UserProvider>(context, listen: false).getUserById(otherUserId)
          : Future.value(null),
      builder: (context, snapshot) {
        // For group chats or while loading user data, show placeholder info
        String displayName = chat.isGroup ? 'Group Chat' : 'Loading...';
        String? photoUrl;
        
        if (snapshot.hasData && snapshot.data != null) {
          displayName = snapshot.data!.displayName;
          photoUrl = snapshot.data!.photoUrl;
        }
        
        final unreadCount = chat.unreadCount[currentUserId] ?? 0;
        
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(
                    chat.isGroup ? Icons.group : Icons.person,
                    color: Colors.grey.shade600,
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                chat.lastMessageTime != null
                    ? timeago.format(chat.lastMessageTime.toDate(), locale: 'en_short')
                    : '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  chat.lastMessageText ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chatDetail,
              arguments: {
                'chatId': chat.id,
                'isGroup': chat.isGroup,
              },
            );
          },
        );
      },
    );
  }
}

class NewChatSheet extends StatefulWidget {
  final Function(String) onUserSelected;
  
  const NewChatSheet({
    Key? key,
    required this.onUserSelected,
  }) : super(key: key);
  
  @override
  _NewChatSheetState createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  String _searchQuery = '';
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  
  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final results = await userProvider.searchUsers(query);
      
      // Filter out current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid;
      
      if (currentUserId != null) {
        results.removeWhere((user) => user.id == currentUserId);
      }
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'New Message',
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
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for people',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),
        
        SizedBox(height: 16),
        
        if (_isSearching)
          Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchQuery.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Search for people to message',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_searchResults.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No users found for "$_searchQuery"',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(user.displayName.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.district),
                  onTap: () => widget.onUserSelected(user.id),
                );
              },
            ),
          ),
      ],
    );
  }
}