import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turikumwe/core/constants/app_colors.dart';
import 'package:turikumwe/core/constants/app_sizes.dart';
import 'package:turikumwe/core/utils/date_formatter.dart';
import 'package:turikumwe/data/models/comment_model.dart';
import 'package:turikumwe/data/models/story_model.dart';
import 'package:turikumwe/presentation/blocs/story/story_bloc.dart';
import 'package:turikumwe/presentation/blocs/comment/comment_bloc.dart';
import 'package:turikumwe/presentation/widgets/common/loading_indicator.dart';
import 'package:turikumwe/presentation/widgets/common/user_avatar.dart';
import 'package:turikumwe/presentation/widgets/story/story_action_bar.dart';
import 'package:turikumwe/presentation/widgets/comment/comment_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

class StoryDetailScreen extends StatefulWidget {
  final String storyId;
  
  const StoryDetailScreen({
    Key? key,
    required this.storyId,
  }) : super(key: key);

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadStoryDetails();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  void _loadStoryDetails() {
    context.read<StoryBloc>().add(FetchStoryDetailEvent(widget.storyId));
    context.read<CommentBloc>().add(FetchCommentsEvent(widget.storyId));
  }
  
  void _shareStory(StoryModel story) {
    final String shareText = '${story.title}\n\nCheck out this story on Turikumwe!\n\nDownload the app: https://turikumwe.app';
    Share.share(shareText);
  }
  
  void _submitComment() {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      context.read<CommentBloc>().add(
        AddCommentEvent(
          storyId: widget.storyId,
          content: comment,
        ),
      );
      _commentController.clear();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StoryBloc, StoryState>(
        builder: (context, state) {
          if (state is StoryDetailLoading) {
            return const LoadingIndicator();
          } else if (state is StoryDetailLoaded) {
            return _buildStoryDetail(state.story);
          } else if (state is StoryDetailError) {
            return _buildErrorState(state.message);
          }
          return const SizedBox();
        },
      ),
    );
  }
  
  Widget _buildStoryDetail(StoryModel story) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(story),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAuthorRow(story),
                const SizedBox(height: 16),
                StoryActionBar(
                  likesCount: story.likesCount,
                  commentsCount: story.commentsCount,
                  isLiked: story.isLiked,
                  isBookmarked: story.isBookmarked,
                  onLikePressed: () {
                    context.read<StoryBloc>().add(ToggleLikeStoryEvent(story.id));
                  },
                  onBookmarkPressed: () {
                    context.read<StoryBloc>().add(ToggleBookmarkStoryEvent(story.id));
                  },
                  onSharePressed: () => _shareStory(story),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  story.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (story.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: story.tags
                        .map((tag) => _buildTagChip(tag))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildCommentSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppBar(StoryModel story) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: story.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: story.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.grey200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.grey200,
                  child: const Icon(Icons.error),
                ),
              )
            : Container(
                color: AppColors.grey200,
                child: const Icon(
                  Icons.image,
                  size: 64,
                  color: AppColors.grey400,
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareStory(story),
        ),
        if (story.isOwnedByCurrentUser)
          _buildMoreOptionsMenu(story),
      ],
    );
  }
  
  Widget _buildMoreOptionsMenu(StoryModel story) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.pushNamed(
            context,
            '/edit-story',
            arguments: story,
          );
        } else if (value == 'delete') {
          _showDeleteConfirmation(story);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAuthorRow(StoryModel story) {
    return Row(
      children: [
        UserAvatar(
          imageUrl: story.author.profileImage,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.author.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                DateFormatter.formatToTimeAgo(story.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(tag),
      backgroundColor: AppColors.secondary.withOpacity(0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Widget _buildCommentSection() {
    return BlocBuilder<CommentBloc, CommentState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CommentsLoaded) {
          return _buildCommentsList(state.comments);
        } else if (state is CommentsError) {
          return Text(
            'Could not load comments: ${state.message}',
            style: const TextStyle(color: AppColors.error),
          );
        }
        return const SizedBox();
      },
    );
  }
  
  Widget _buildCommentsList(List<CommentModel> comments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comments.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No comments yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to comment',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final comment = comments[index];
              return CommentItem(
                comment: comment,
                onLikePressed: () {
                  context.read<CommentBloc>().add(
                    ToggleLikeCommentEvent(comment.id),
                  );
                },
              );
            },
          ),
        const SizedBox(height: 24),
        _buildCommentInput(),
      ],
    );
  }
  
  Widget _buildCommentInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            minLines: 1,
            maxLines: 5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _submitComment,
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load story',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStoryDetails,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<StoryBloc>().add(DeleteStoryEvent(story.id));
              Navigator.pop(context); // Return to stories list
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}