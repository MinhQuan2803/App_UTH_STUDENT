import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/reaction_model.dart';
import '../services/post_service.dart';
import '../widgets/custom_notification.dart';

class ReactionListScreen extends StatefulWidget {
  final String postId;
  final int initialLikesCount;
  final int initialDislikesCount;

  const ReactionListScreen({
    super.key,
    required this.postId,
    required this.initialLikesCount,
    required this.initialDislikesCount,
  });

  @override
  State<ReactionListScreen> createState() => _ReactionListScreenState();
}

class _ReactionListScreenState extends State<ReactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostService _postService = PostService();

  // State cho từng tab
  List<ReactionUser> _allReactions = [];
  List<ReactionUser> _likeReactions = [];
  List<ReactionUser> _dislikeReactions = [];

  bool _isLoadingAll = false;
  bool _isLoadingLikes = false;
  bool _isLoadingDislikes = false;

  bool _isLoadingMoreAll = false;
  bool _isLoadingMoreLikes = false;
  bool _isLoadingMoreDislikes = false;

  int _currentPageAll = 1;
  int _currentPageLikes = 1;
  int _currentPageDislikes = 1;

  bool _hasMoreAll = true;
  bool _hasMoreLikes = true;
  bool _hasMoreDislikes = true;

  int _totalLikes = 0;
  int _totalDislikes = 0;
  int _totalAll = 0;

  final ScrollController _scrollControllerAll = ScrollController();
  final ScrollController _scrollControllerLikes = ScrollController();
  final ScrollController _scrollControllerDislikes = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _totalLikes = widget.initialLikesCount;
    _totalDislikes = widget.initialDislikesCount;
    _totalAll = _totalLikes + _totalDislikes;

    // Load data cho tab đầu tiên
    _loadReactions('all');

    // Lắng nghe thay đổi tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentTab = _tabController.index;
        if (currentTab == 0 && _allReactions.isEmpty) {
          _loadReactions('all');
        } else if (currentTab == 1 && _likeReactions.isEmpty) {
          _loadReactions('like');
        } else if (currentTab == 2 && _dislikeReactions.isEmpty) {
          _loadReactions('dislike');
        }
      }
    });

    // Lắng nghe scroll để load more
    _scrollControllerAll.addListener(() => _onScroll('all'));
    _scrollControllerLikes.addListener(() => _onScroll('like'));
    _scrollControllerDislikes.addListener(() => _onScroll('dislike'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerAll.dispose();
    _scrollControllerLikes.dispose();
    _scrollControllerDislikes.dispose();
    super.dispose();
  }

  void _onScroll(String type) {
    ScrollController controller;
    bool hasMore;
    bool isLoadingMore;

    switch (type) {
      case 'like':
        controller = _scrollControllerLikes;
        hasMore = _hasMoreLikes;
        isLoadingMore = _isLoadingMoreLikes;
        break;
      case 'dislike':
        controller = _scrollControllerDislikes;
        hasMore = _hasMoreDislikes;
        isLoadingMore = _isLoadingMoreDislikes;
        break;
      default:
        controller = _scrollControllerAll;
        hasMore = _hasMoreAll;
        isLoadingMore = _isLoadingMoreAll;
    }

    if (controller.position.pixels >=
            controller.position.maxScrollExtent - 200 &&
        hasMore &&
        !isLoadingMore) {
      _loadMore(type);
    }
  }

  Future<void> _loadReactions(String type, {bool refresh = false}) async {
    if (refresh) {
      setState(() {
        switch (type) {
          case 'like':
            _currentPageLikes = 1;
            _likeReactions.clear();
            break;
          case 'dislike':
            _currentPageDislikes = 1;
            _dislikeReactions.clear();
            break;
          default:
            _currentPageAll = 1;
            _allReactions.clear();
        }
      });
    }

    // Set loading state
    setState(() {
      switch (type) {
        case 'like':
          _isLoadingLikes = true;
          break;
        case 'dislike':
          _isLoadingDislikes = true;
          break;
        default:
          _isLoadingAll = true;
      }
    });

    try {
      final response = await _postService.getPostReactions(
        postId: widget.postId,
        type: type,
        page: type == 'like'
            ? _currentPageLikes
            : type == 'dislike'
                ? _currentPageDislikes
                : _currentPageAll,
        limit: 20,
      );

      final reactionResponse = ReactionListResponse.fromJson(response);

      if (mounted) {
        setState(() {
          switch (type) {
            case 'like':
              _likeReactions = reactionResponse.reactions;
              _hasMoreLikes = reactionResponse.pagination.hasMore;
              _totalLikes = reactionResponse.counts.likes;
              _isLoadingLikes = false;
              break;
            case 'dislike':
              _dislikeReactions = reactionResponse.reactions;
              _hasMoreDislikes = reactionResponse.pagination.hasMore;
              _totalDislikes = reactionResponse.counts.dislikes;
              _isLoadingDislikes = false;
              break;
            default:
              _allReactions = reactionResponse.reactions;
              _hasMoreAll = reactionResponse.pagination.hasMore;
              _totalAll = reactionResponse.counts.total;
              _totalLikes = reactionResponse.counts.likes;
              _totalDislikes = reactionResponse.counts.dislikes;
              _isLoadingAll = false;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading reactions: $e');
      if (mounted) {
        setState(() {
          switch (type) {
            case 'like':
              _isLoadingLikes = false;
              break;
            case 'dislike':
              _isLoadingDislikes = false;
              break;
            default:
              _isLoadingAll = false;
          }
        });
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _loadMore(String type) async {
    setState(() {
      switch (type) {
        case 'like':
          _isLoadingMoreLikes = true;
          _currentPageLikes++;
          break;
        case 'dislike':
          _isLoadingMoreDislikes = true;
          _currentPageDislikes++;
          break;
        default:
          _isLoadingMoreAll = true;
          _currentPageAll++;
      }
    });

    try {
      final response = await _postService.getPostReactions(
        postId: widget.postId,
        type: type,
        page: type == 'like'
            ? _currentPageLikes
            : type == 'dislike'
                ? _currentPageDislikes
                : _currentPageAll,
        limit: 20,
      );

      final reactionResponse = ReactionListResponse.fromJson(response);

      if (mounted) {
        setState(() {
          switch (type) {
            case 'like':
              _likeReactions.addAll(reactionResponse.reactions);
              _hasMoreLikes = reactionResponse.pagination.hasMore;
              _isLoadingMoreLikes = false;
              break;
            case 'dislike':
              _dislikeReactions.addAll(reactionResponse.reactions);
              _hasMoreDislikes = reactionResponse.pagination.hasMore;
              _isLoadingMoreDislikes = false;
              break;
            default:
              _allReactions.addAll(reactionResponse.reactions);
              _hasMoreAll = reactionResponse.pagination.hasMore;
              _isLoadingMoreAll = false;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading more: $e');
      if (mounted) {
        setState(() {
          switch (type) {
            case 'like':
              _isLoadingMoreLikes = false;
              _currentPageLikes--;
              break;
            case 'dislike':
              _isLoadingMoreDislikes = false;
              _currentPageDislikes--;
              break;
            default:
              _isLoadingMoreAll = false;
              _currentPageAll--;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cảm xúc',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.subtitle,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Tất cả $_totalAll'),
            Tab(text: '❤️ $_totalLikes'),
            Tab(text: '👎 $_totalDislikes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReactionList(_allReactions, _isLoadingAll, _isLoadingMoreAll,
              _scrollControllerAll, 'all'),
          _buildReactionList(_likeReactions, _isLoadingLikes,
              _isLoadingMoreLikes, _scrollControllerLikes, 'like'),
          _buildReactionList(_dislikeReactions, _isLoadingDislikes,
              _isLoadingMoreDislikes, _scrollControllerDislikes, 'dislike'),
        ],
      ),
    );
  }

  Widget _buildReactionList(
    List<ReactionUser> reactions,
    bool isLoading,
    bool isLoadingMore,
    ScrollController scrollController,
    String type,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadReactions(type, refresh: true),
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: reactions.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == reactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final reaction = reactions[index];
          return _buildReactionItem(reaction);
        },
      ),
    );
  }

  Widget _buildReactionItem(ReactionUser reaction) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {'username': reaction.username},
        );
      },
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundImage: reaction.avatarUrl != null
                    ? CachedNetworkImageProvider(reaction.avatarUrl!)
                    : null,
                backgroundColor: AppColors.imagePlaceholder,
                child: reaction.avatarUrl == null
                    ? Text(
                        reaction.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reaction.displayName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (reaction.bio != null && reaction.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        reaction.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.subtitle.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Reaction icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: reaction.reactionType == 'like'
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reaction.reactionType == 'like'
                    ? Icons.favorite
                    : Icons.thumb_down,
                size: 18,
                color: reaction.reactionType == 'like'
                    ? AppColors.primary
                    : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Chưa có cảm xúc nào',
            style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
