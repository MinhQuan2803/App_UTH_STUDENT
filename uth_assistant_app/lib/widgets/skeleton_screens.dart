import 'package:flutter/material.dart';
import 'package:uth_assistant_app/widgets/shimmer_loading.dart';
import '../config/app_theme.dart';
import 'modern_app_bar.dart';

/// Full Skeleton Screen cho ProfileScreen
class ProfileSkeletonScreen extends StatelessWidget {
  final String appBarTitle;
  final bool automaticallyImplyLeading;

  const ProfileSkeletonScreen({
    super.key,
    this.appBarTitle = 'Trang cá nhân',
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: Shimmer(
        child: CustomScrollView(
          slivers: [
            // Profile Header Skeleton
            const SliverToBoxAdapter(
              child: SkeletonProfileHeader(),
            ),

            // "Tất cả bài viết" Section
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: SkeletonBox(
                  width: 120,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Posts Skeleton List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SkeletonPostCard(),
                childCount: 3, // Show 3 skeleton posts
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Loading cho HomeScreen - Khớp với HomeScreen thực tế
class HomeSkeletonScreen extends StatelessWidget {
  const HomeSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Shimmer(
        child: CustomScrollView(
          slivers: [
            // News Section Skeleton - Horizontal ListView
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SkeletonBox(
                        width: 150,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Horizontal scroll news cards
                    SizedBox(
                      height: 200, // Height để chứa news card
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) =>
                            const SkeletonNewsItem(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Posts Section Skeleton
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SkeletonPostCard(),
                childCount: 4, // Show 4 skeleton posts
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton cho News List (compact version) - Horizontal scroll
class NewsListSkeleton extends StatelessWidget {
  const NewsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) => const SkeletonNewsItem(),
        ),
      ),
    );
  }
}

/// Skeleton cho Posts List (compact version)
class PostsListSkeleton extends StatelessWidget {
  final int itemCount;

  const PostsListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(
          itemCount,
          (index) => const SkeletonPostCard(),
        ),
      ),
    );
  }
}
