// presentation/screens/messages/chat_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_bar.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final bool isGroup;
  
  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    this.isGroup = false,
  }) : super(key: key);
  
  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  ChatModel? _currentChat;
  UserModel? _otherUser;
  List<File> _selectedImages = [];
  MessageModel? _replyingTo;
  
  @override
  void initState() {
    super.initState();
    _loadChat();
    
    // Listen for new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMessageListener();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.setCurrentChat(widget.chatId);
      
      setState(() {
        _currentChat = chatProvider.currentChat;
      });
      
      // For one-to-one chats, get the other user's info
      if (!widget.isGroup && _currentChat != null) {
        await _loadOtherUserInfo();
      }
      
      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error loading chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadOtherUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    
    if (currentUserId == null || _currentChat == null) return;
    
    // Find the other participant
    final otherParticipants = _currentChat!.participantIds
        .where((id) => id != currentUserId)
        .toList();
    
    if (otherParticipants.isEmpty) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final otherUser = await userProvider.getUserById(otherParticipants.first);
    
    if (otherUser != null) {
      setState(() {
        _otherUser = otherUser;
      });
    }
  }
  
  void _setupMessageListener() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.listenToMessages(widget.chatId).listen((messages) {
      // Scroll to bottom when new messages arrive
      if (messages.isNotEmpty && _scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImages.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      Map<String, dynamic>? replyData;
      if (_replyingTo != null) {
        replyData = {
          'messageId': _replyingTo!.id,
          'senderId': _replyingTo!.senderId,
          'text': _replyingTo!.text,
        };
      }
      
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: message,
        mediaFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        mediaType: _selectedImages.isNotEmpty ? 'image' : null,
        replyTo: replyData,
      );
      
      // Clear input and reset state
      _messageController.clear();
      setState(() {
        _selectedImages = [];
        _replyingTo = null;
      });
      
      // Scroll to bottom to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1200,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images')),
      );
    }
  }
  
  void _showReplyingTo(MessageModel message) {
    setState(() {
      _replyingTo = message;
    });
    
    // Focus on the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }
  
  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isGroup
            ? (_currentChat?.groupId ?? 'Group Chat')
            : (_otherUser?.displayName ?? 'Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show chat options
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: messages.length,
                          reverse: true, // Show newest messages at the bottom
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _buildMessageItem(message);
                          },
                        ),
                ),
                
                // Selected images preview
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 100,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
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
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
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
                
                // Replying to indicator
                if (_replyingTo != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          color: AppTheme.primaryColor,
                          margin: EdgeInsets.only(right: 8),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Replying to',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                _replyingTo!.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                
                // Message input
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: _pickImages,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _sendMessage,
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        mini: true,
                        child: _isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
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
            size: 64,
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
            'Start the conversation!',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageItem(MessageModel message) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;
    final isMyMessage = message.senderId == currentUserId;
    
    return GestureDetector(
      onLongPress: () {
        // Show message options (reply, delete, etc.)
        _showMessageOptions(message);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: isMyMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Reply indicator
            if (message.replyTo != null)
              Container(
                margin: EdgeInsets.only(
                  bottom: 4,
                  left: isMyMessage ? 0 : 40,
                  right: isMyMessage ? 40 : 0,
                ),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  message.replyTo!['text'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            
            Row(
              mainAxisAlignment: isMyMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // User avatar (only for other users' messages)
                if (!isMyMessage)
                  FutureBuilder<UserModel?>(
                    future: Provider.of<UserProvider>(context, listen: false)
                        .getUserById(message.senderId),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: snapshot.data?.photoUrl != null
                            ? NetworkImage(snapshot.data!.photoUrl!)
                            : null,
                        child: snapshot.data?.photoUrl == null
                            ? Icon(Icons.person, size: 16)
                            : null,
                      );
                    },
                  ),
                
                SizedBox(width: isMyMessage ? 0 : 8),
                
                // Message content
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: isMyMessage ? 64 : 0, right: isMyMessage ? 0 : 64),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMyMessage
                          ? AppTheme.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMyMessage ? Radius.circular(0) : null,
                        bottomLeft: !isMyMessage ? Radius.circular(0) : null,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media content
                        if (message.mediaUrls != null && message.mediaUrls!.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 250,
                            ),
                            margin: EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: message.mediaUrls!.length == 1
                                  ? CachedNetworkImage(
                                      imageUrl: message.mediaUrls!.first,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade300,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(Icons.broken_image),
                                      ),
                                    )
                                  : GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: message.mediaUrls!.map((url) {
                                        return CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey.shade300,
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey.shade300,
                                            child: Icon(Icons.broken_image),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                        
                        // Text content
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMyMessage ? Colors.white : Colors.black,
                          ),
                        ),
                        
                        // Timestamp
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            timeago.format(message.timestamp.toDate(), locale: 'en_short'),
                            style: TextStyle(
                              color: isMyMessage
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMessageOptions(MessageModel message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final isMyMessage = message.senderId == currentUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.reply),
                title: Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _showReplyingTo(message);
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmation(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteMessage(MessageModel message) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.deleteMessage(widget.chatId, message.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message')),
      );
    }
  }
}