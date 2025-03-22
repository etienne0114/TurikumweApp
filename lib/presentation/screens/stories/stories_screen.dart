import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turikumwe/core/constants/app_colors.dart';
import 'package:turikumwe/core/constants/app_sizes.dart';
import 'package:turikumwe/data/models/story_model.dart';
import 'package:turikumwe/data/repositories/story_repository_impl.dart';
import 'package:turikumwe/presentation/blocs/story/story_bloc.dart';
import 'package:turikumwe/presentation/widgets/common/custom_app_bar.dart';
import 'package:turikumwe/presentation/widgets/common/loading_indicator.dart';
import 'package:turikumwe/presentation/widgets/common/empty_state.dart';
import 'package:turikumwe/presentation/widgets/common/search_field.dart';
import 'package:turikumwe/presentation/widgets/story/story_item.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadStories();
    _setupScrollListener();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadStories() {
    context.read<StoryBloc>().add(FetchStoriesEvent());
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        final storyBloc = context.read<StoryBloc>();
        final state = storyBloc.state;
        
        if (state is StoriesLoaded && !state.hasReachedMax && !state.isLoading) {
          storyBloc.add(LoadMoreStoriesEvent());
        }
      }
    });
  }
  
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _loadStories();
    } else {
      context.read<StoryBloc>().add(SearchStoriesEvent(query));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Stories',
        showBackButton: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hintText: 'Search stories...',
            ),
          ),
          Expanded(
            child: BlocBuilder<StoryBloc, StoryState>(
              builder: (context, state) {
                if (state is StoriesInitial) {
                  return const LoadingIndicator();
                } else if (state is StoriesLoading && state.isFirstLoad) {
                  return const LoadingIndicator();
                } else if (state is StoriesLoaded) {
                  return _buildStoriesList(state.stories, state.isLoading);
                } else if (state is StoriesError) {
                  return _buildErrorState(state.message);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-story');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildStoriesList(List<StoryModel> stories, bool isLoadingMore) {
    if (stories.isEmpty) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'No Stories Found',
        subtitle: 'Be the first to share your story',
        buttonText: 'Create Story',
        onButtonPressed: () {
          Navigator.pushNamed(context, '/create-story');
        },
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadStories();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        itemCount: stories.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == stories.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: StoryItem(
              story: story,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/story-details',
                  arguments: story.id,
                );
              },
              onLikePressed: () {
                context.read<StoryBloc>().add(ToggleLikeStoryEvent(story.id));
              },
            ),
          );
        },
      ),
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
            'Something went wrong',
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
            onPressed: _loadStories,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}