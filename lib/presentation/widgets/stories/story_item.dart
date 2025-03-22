import 'package:flutter/material.dart';
import 'package:turikumwe/core/constants/app_colors.dart';
import 'package:turikumwe/core/constants/app_sizes.dart';
import 'package:turikumwe/core/utils/date_formatter.dart';
import 'package:turikumwe/data/models/story_model.dart';
import 'package:turikumwe/presentation/widgets/common/user_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryItem extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final VoidCallback? onLikePressed;
  
  const StoryItem({
    Key? key,
    required this.story,
    required this.onTap,
    this.onLikePressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (story.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
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
                ),
              ),
              
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Preview content
                  Text(
                    story.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Author info and stats
                  Row(
                    children: [
                      // Author avatar and name
                      UserAvatar(
                        imageUrl: story.author.profileImage,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.author.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      
                      // Story stats
                      Row(
                        children: [
                          // Like button
                          IconButton(
                            icon: Icon(
                              story.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: story.isLiked ? Colors.red : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: onLikePressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(right: 4),
                            splashRadius: 20,
                          ),
                          Text(
                            story.likesCount.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Comments count
                          Icon(
                            Icons.comment_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            story.commentsCount.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (story.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: story.tags
                          .take(3)
                          .map((tag) => _buildTag(context, tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
      ),
      child: Text(
        '#$tag',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.secondary,
        ),
      ),
    );
  }
}