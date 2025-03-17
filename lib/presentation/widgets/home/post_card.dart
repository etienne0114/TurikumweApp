// presentation/widgets/home/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/user_provider.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onProfileTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.currentUser?.id;
    final isLiked = post.likes.contains(currentUserId);
    
    return FutureBuilder<UserModel?>(
      future: userProvider.getUserById(post.authorId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              ListTile(
                leading: GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: author?.photoUrl != null
                        ? CachedNetworkImageProvider(author!.photoUrl!)
                        : null,
                    child: author?.photoUrl == null
                        ? Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                ),
                title: isLoading
                    ? Container(
                        width: 100,
                        height: 20,
                        color: Colors.grey.shade300,
                      )
                    : Row(
                        children: [
                          Text(
                            author?.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (author?.isVerified == true)
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
                subtitle: Row(
                  children: [
                    Text(timeago.format(post.createdAt.toDate())),
                    if (post.location != null) ...[
                      SizedBox(width: 4),
                      Icon(Icons.location_on, size: 12, color: Colors.grey),
                      SizedBox(width: 2),
                      Text(
                        post.location!,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    // Show post options
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildPostOptionsSheet(context),
                    );
                  },
                ),
              ),
              
              // Post content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(post.content),
              ),
              
              // Post images
              if (post.imageUrls.isNotEmpty)
                Container(
                  height: post.imageUrls.length > 1 ? 200 : null,
                  child: post.imageUrls.length == 1
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrls.first,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(Icons.error),
                          ),
                          fit: BoxFit.cover,
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              child: CachedNetworkImage(
                                imageUrl: post.imageUrls[index],
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(Icons.error),
                                ),
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                ),
              
              // Post tags
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: post.tags.map((tag) {
                      return Chip(
                        label: Text(
                          '#$tag',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
                  ),
                ),
              
              // Post stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (post.likes.isNotEmpty)
                      Text(
                        '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
// presentation/widgets/home/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/user_provider.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onProfileTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.currentUser?.id;
    final isLiked = post.likes.contains(currentUserId);
    
    return FutureBuilder<UserModel?>(
      future: userProvider.getUserById(post.authorId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              ListTile(
                leading: GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: author?.photoUrl != null
                        ? CachedNetworkImageProvider(author!.photoUrl!)
                        : null,
                    child: author?.photoUrl == null
                        ? Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                ),
                title: isLoading
                    ? Container(
                        width: 100,
                        height: 20,
                        color: Colors.grey.shade300,
                      )
                    : Row(
                        children: [
                          Text(
                            author?.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (author?.isVerified == true)
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
                subtitle: Row(
                  children: [
                    Text(timeago.format(post.createdAt.toDate())),
                    if (post.location != null) ...[
                      SizedBox(width: 4),
                      Icon(Icons.location_on, size: 12, color: Colors.grey),
                      SizedBox(width: 2),
                      Text(
                        post.location!,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    // Show post options
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildPostOptionsSheet(context),
                    );
                  },
                ),
              ),
              
              // Post content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(post.content),
              ),
              
              // Post images
              if (post.imageUrls.isNotEmpty)
                Container(
                  height: post.imageUrls.length > 1 ? 200 : null,
                  child: post.imageUrls.length == 1
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrls.first,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(Icons.error),
                          ),
                          fit: BoxFit.cover,
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              child: CachedNetworkImage(
                                imageUrl: post.imageUrls[index],
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(Icons.error),
                                ),
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                ),
              
              // Post tags
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: post.tags.map((tag) {
                      return Chip(
                        label: Text(
                          '#$tag',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
                  ),
                ),
              
              // Post stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (post.likes.isNotEmpty)
                      Text(
                        '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    if (post.likes.isNotEmpty && post.commentCount > 0)
                      SizedBox(width: 8),
                    if (post.commentCount > 0)
                      Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              
              Divider(),
              
              // Post actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: onLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color: isLiked ? Colors.red : null,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onComment,
                    icon: Icon(Icons.comment_outlined),
                    label: Text('Comment'),
                  ),
                  TextButton.icon(
                    onPressed: onShare,
                    icon: Icon(Icons.share_outlined),
                    label: Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPostOptionsSheet(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.currentUser?.id;
    final isMyPost = post.authorId == currentUserId;
    final isAdmin = userProvider.currentUser?.role == 'admin';
    final isModerator = userProvider.currentUser?.role == 'moderator';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMyPost) ...[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit post
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show delete confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Post'),
                    content: Text('Are you sure you want to delete this post?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Delete post
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (!isMyPost) ...[
            ListTile(
              leading: Icon(Icons.bookmark_border),
              title: Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                // Save post
              },
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                onProfileTap();
              },
            ),
          ],
          if (!isMyPost && (isAdmin || isModerator)) ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.flag, color: Colors.orange),
              title: Text(
                'Moderate Post',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show moderation options
              },
            ),
          ],
          if (!isMyPost) ...[
            ListTile(
              leading: Icon(Icons.report, color: Colors.red),
              title: Text(
                'Report Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show report dialog
              },
            ),
          ],
        ],
      ),
    );
  }
}style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    if (post.likes.isNotEmpty && post.commentCount > 0)
                      SizedBox(width: 8),
                    if (post.commentCount > 0)
                      Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
     