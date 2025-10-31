import 'package:flutter/material.dart';
import '../services/relationship_service.dart';
import '../services/follow_service.dart';

class FollowingListScreen extends StatefulWidget {
  final String username;

  const FollowingListScreen({
    super.key,
    required this.username,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final RelationshipService _relationshipService = RelationshipService();
  final FollowService _followService = FollowService();

  List<UserRelationship> _following = [];
  bool _isLoading = true;
  String? _error;

  // Track follow states for optimistic updates
  final Map<String, bool> _followStates = {};

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final following =
          await _relationshipService.getFollowing(widget.username);

      setState(() {
        _following = following;
        // Initialize follow states
        for (var user in following) {
          _followStates[user.id] = user.isFollowing;
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
        title: Text('Đang theo dõi ${widget.username}'),
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
              onPressed: _loadFollowing,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: Theme.of(context).primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Chưa theo dõi ai',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          return _buildFollowingItem(user);
        },
      ),
    );
  }

  Widget _buildFollowingItem(UserRelationship user) {
    final isFollowing = _followStates[user.id] ?? false;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(user.username),
        child: CircleAvatar(
          radius: 24,
          backgroundImage:
              user.profileImg != null ? NetworkImage(user.profileImg!) : null,
          child: user.profileImg == null
              ? Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(user.username),
        child: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: user.fullName != null ? Text(user.fullName!) : null,
      trailing: SizedBox(
        width: 100,
        child: ElevatedButton(
          onPressed: () => _handleFollowToggle(user),
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
