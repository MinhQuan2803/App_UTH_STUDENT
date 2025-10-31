import 'package:flutter/material.dart';
import '../services/relationship_service.dart';
import '../services/follow_service.dart';

class FollowersListScreen extends StatefulWidget {
  final String username;

  const FollowersListScreen({
    super.key,
    required this.username,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final RelationshipService _relationshipService = RelationshipService();
  final FollowService _followService = FollowService();

  List<UserRelationship> _followers = [];
  bool _isLoading = true;
  String? _error;

  // Track follow states for optimistic updates
  final Map<String, bool> _followStates = {};

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final followers =
          await _relationshipService.getFollowers(widget.username);

      setState(() {
        _followers = followers;
        // Initialize follow states
        for (var follower in followers) {
          _followStates[follower.id] = follower.isFollowing;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFollowToggle(UserRelationship user) async {
    final isCurrentlyFollowing = _followStates[user.id] ?? false;

    // Optimistic update
    setState(() {
      _followStates[user.id] = !isCurrentlyFollowing;
    });

    try {
      if (isCurrentlyFollowing) {
        await _followService.unfollowUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã bỏ theo dõi ${user.username}')),
          );
        }
      } else {
        await _followService.followUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã theo dõi ${user.username}')),
          );
        }
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _followStates[user.id] = isCurrentlyFollowing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToProfile(String username) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'username': username},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Người theo dõi ${widget.username}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không thể tải danh sách',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: Theme.of(context).primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Chưa có người theo dõi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final follower = _followers[index];
          return _buildFollowerItem(follower);
        },
      ),
    );
  }

  Widget _buildFollowerItem(UserRelationship follower) {
    final isFollowing = _followStates[follower.id] ?? false;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(follower.username),
        child: CircleAvatar(
          radius: 24,
          backgroundImage: follower.profileImg != null
              ? NetworkImage(follower.profileImg!)
              : null,
          child: follower.profileImg == null
              ? Text(
                  follower.username[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(follower.username),
        child: Text(
          follower.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: follower.fullName != null ? Text(follower.fullName!) : null,
      trailing: SizedBox(
        width: 100,
        child: ElevatedButton(
          onPressed: () => _handleFollowToggle(follower),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing
                ? Colors.grey.shade300
                : Theme.of(context).primaryColor,
            foregroundColor: isFollowing ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            isFollowing ? 'Đang theo dõi' : 'Theo dõi',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
