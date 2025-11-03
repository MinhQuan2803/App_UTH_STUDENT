import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/home_post_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/modern_app_bar.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import 'package:flutter/foundation.dart';

class UserPostsScreen extends StatefulWidget {
  final String username;
  const UserPostsScreen({super.key, required this.username});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  String? _myUsername; // Username của người đang đăng nhập

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    // Tải username của chính mình để so sánh quyền Sửa/Xóa
    await _loadUsername();
    // Tải bài viết của user được truyền vào
    await _loadPosts(forceRefresh: forceRefresh);
  }

  Future<void> _loadUsername() async {
    final username = await _authService.getUsername();
    if (mounted) {
      setState(() => _myUsername = username);
    }
  }

  Future<void> _loadPosts({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });
    try {
      final posts = await _postService.getProfilePosts(
        username: widget.username,
        page: 0,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Bài viết của ${widget.username}',
      ),
      body: _buildPostsList(),
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_postsError!,
                  textAlign: TextAlign.center, style: AppTextStyles.errorText),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () => _loadPosts(forceRefresh: true),
                text: 'Thử lại',
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add,
                  size: 80, color: AppColors.subtitle.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Người dùng này chưa có bài viết nào',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular
                    .copyWith(color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị danh sách bài viết (dùng HomePostCard)
    return RefreshIndicator(
      onRefresh: () => _loadAllData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];

          return HomePostCard(
            key: ValueKey(post.id),
            post: post,
            username: _myUsername,
            onPostDeleted: () {
              setState(() {
                _posts.removeAt(index);
              });
            },
            onPostUpdated: () {
              _loadPosts(forceRefresh: true);
            },
          );
        },
      ),
    );
  }
}
