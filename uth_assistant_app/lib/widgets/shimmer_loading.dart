import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget tạo hiệu ứng Shimmer - ánh sáng quét qua
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Gradient? gradient;

  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1500),
    this.gradient,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return (widget.gradient ??
                    LinearGradient(
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[100]!,
                        Colors.grey[300]!,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: const Alignment(-1.0, -0.3),
                      end: const Alignment(1.0, 0.3),
                      tileMode: TileMode.clamp,
                    ))
                .createShader(
              Rect.fromLTWH(
                bounds.left - bounds.width * _controller.value,
                bounds.top,
                bounds.width * 3,
                bounds.height,
              ),
            );
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

/// Container placeholder cho skeleton loading
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Circle placeholder cho avatar
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsets? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton cho Post Card - Khớp với HomePostCard thực tế
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar + Name + Time + Menu (padding 8.0 như HomePostCard)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Avatar với border như thật (radius: 18)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: const SkeletonCircle(size: 36), // radius 18 * 2
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 120,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          SkeletonBox(
                            width: 60,
                            height: 11,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 3),
                          SkeletonBox(
                            width: 11,
                            height: 11,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu button placeholder
                SkeletonBox(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),

          // Content text (padding horizontal 10.0, vertical 6.0)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                SkeletonBox(
                  height: 14,
                  width: double.infinity * 0.7,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Image placeholder (full width, no padding, constrained height)
          SkeletonBox(
            height: 250,
            width: double.infinity,
            borderRadius:
                BorderRadius.circular(0), // No radius như HomePostCard
          ),

          // Action buttons (padding fromLTRB(12.0, 8.0, 12.0, 12.0))
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Container với border và shadow như thật
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like
                      _buildActionButtonSkeleton(),
                      _buildDivider(),
                      // Dislike
                      _buildActionButtonSkeleton(),
                      _buildDivider(),
                      // Comment
                      _buildActionButtonSkeleton(),
                      _buildDivider(),
                      // Share
                      _buildActionButtonSkeleton(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider dày 8px
          Container(
            height: 8,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Row(
        children: [
          SkeletonBox(
            width: 20,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(width: 4),
          SkeletonBox(
            width: 16,
            height: 13,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey[200],
    );
  }
}

/// Skeleton cho News Item - Khớp với NotificationCard thực tế
class SkeletonNewsItem extends StatelessWidget {
  const SkeletonNewsItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (height: 100, borderRadius chỉ top)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
          ),

          // Content (padding: 6.0)
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (2 lines)
                SkeletonBox(
                  height: 14,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                SkeletonBox(
                  height: 14,
                  width: double.infinity * 0.7,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 2),
                // Date
                SkeletonBox(
                  height: 12,
                  width: 80,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton cho Profile Header
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Avatar
          const SkeletonCircle(size: 100),
          const SizedBox(height: 16),

          // Username
          SkeletonBox(
            width: 150,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),

          // Bio
          SkeletonBox(
            width: 200,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatSkeleton(),
              _buildStatSkeleton(),
              _buildStatSkeleton(),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SkeletonBox(
                  height: 44,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonBox(
                  height: 44,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        SkeletonBox(
          width: 40,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        SkeletonBox(
          width: 60,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
