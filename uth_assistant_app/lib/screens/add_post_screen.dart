import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Cho kDebugMode
import '../config/app_theme.dart';
import '../services/post_service.dart';
import '../services/upload_service.dart';
import '../services/profile_service.dart';
import '../models/post_model.dart';
import '../widgets/custom_notification.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  final Post? post; // Null = tạo mới, có giá trị = chỉnh sửa

  const AddPostScreen({super.key, this.post});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();
  final UploadService _uploadService = UploadService();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  bool _isPostButtonEnabled = false;
  bool _isPosting = false;
  late AnimationController _animationController;

  List<String> _imageUrls = []; // URLs từ server (khi edit)
  List<File> _selectedImages = []; // Files được chọn từ thiết bị

  // Thông tin user hiện tại
  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;

  // Privacy setting
  String _selectedPrivacy = 'public'; // 'public', 'friends', 'private'

  bool get _isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final post = widget.post!;
      _contentController.text = post.text;
      _imageUrls = List.from(post.mediaUrls);
      _selectedPrivacy = post.privacy; // Load privacy từ post đang edit
    }

    _contentController.addListener(_validatePost);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _validatePost();
    _loadCurrentUser();
  }

  /// Load thông tin user hiện tại
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
        CustomNotification.error(context, 'Không thể tải thông tin người dùng');
      }
    }
  }

  void _validatePost() {
    final bool canPost = _contentController.text.trim().isNotEmpty;

    if (canPost != _isPostButtonEnabled) {
      setState(() => _isPostButtonEnabled = canPost);
      if (canPost) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_validatePost);
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final text = _contentController.text.trim();
    if (!_isPostButtonEnabled) return;

    setState(() => _isPosting = true);

    try {
      // Upload ảnh mới từ thiết bị
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          uploadedUrls = await _uploadService.uploadImages(_selectedImages);
        } catch (uploadError) {
          if (mounted) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Lỗi upload ảnh'),
                content: Text(
                    'Không thể upload ảnh: ${uploadError.toString().replaceFirst('Exception: ', '')}\n\n'
                    'Bạn có muốn đăng bài không có ảnh không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đăng không có ảnh'),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) {
              setState(() => _isPosting = false);
              return;
            }
          }
        }
      }

      // QUAN TRỌNG: Gộp đúng cách
      // _imageUrls = ảnh cũ còn lại (đã trừ đi ảnh đã xóa qua _removeUrlImage)
      // uploadedUrls = ảnh mới vừa upload
      final allImageUrls = [..._imageUrls, ...uploadedUrls];

      if (kDebugMode) {
        print('=== SUBMIT POST DEBUG ===');
        print('📷 imageUrls (old): $_imageUrls');
        print('📤 uploadedUrls (new): $uploadedUrls');
        print('🖼️ allImageUrls (final): $allImageUrls');
        print('📊 Total images: ${allImageUrls.length}');
      }

      if (_isEditMode) {
        await _postService.updatePost(
          postId: widget.post!.id,
          text: text,
          // QUAN TRỌNG: Luôn gửi list (có thể rỗng), không gửi null
          // [] = xóa hết ảnh, [url1, url2] = giữ ảnh
          mediaUrls: allImageUrls,
          privacy: _selectedPrivacy,
        );
        if (mounted) {
          CustomNotification.success(context, 'Đã cập nhật bài viết');
          Navigator.of(context).pop(true);
        }
      } else {
        await _postService.createPost(
          text: text,
          mediaUrls: allImageUrls.isEmpty ? null : allImageUrls,
          privacy: _selectedPrivacy,
        );
        if (mounted) {
          CustomNotification.success(context, 'Đã đăng bài viết');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      final totalImages =
          _selectedImages.length + _imageUrls.length + images.length;
      if (totalImages > 3) {
        if (mounted) {
          CustomNotification.warning(context, 'Chỉ được chọn tối đa 3 ảnh');
        }
        return;
      }

      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    } catch (e) {
      if (mounted) {
        CustomNotification.error(context, 'Lỗi chọn ảnh: $e');
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (kDebugMode) {
        print('🗑️ Removed selected image at index $index');
        print('📸 Remaining selected images: ${_selectedImages.length}');
      }
    });
  }

  void _removeUrlImage(int index) {
    setState(() {
      final removedUrl = _imageUrls[index];
      _imageUrls.removeAt(index);
      if (kDebugMode) {
        print('🗑️ Removed URL image at index $index: $removedUrl');
        print('🖼️ Remaining URL images: $_imageUrls');
      }
    });
  }

  /// Hiển thị dialog chọn privacy
  Future<void> _showPrivacySelector() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ai có thể xem bài viết này?'),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrivacyOption(
              icon: Icons.public,
              title: 'Công khai',
              description: 'Bất kỳ ai trên UTH Student',
              value: 'public',
              currentValue: _selectedPrivacy,
            ),
            _PrivacyOption(
              icon: Icons.people,
              title: 'Bạn bè',
              description: 'Chỉ bạn bè của bạn',
              value: 'friends',
              currentValue: _selectedPrivacy,
            ),
            _PrivacyOption(
              icon: Icons.lock,
              title: 'Riêng tư',
              description: 'Chỉ mình bạn',
              value: 'private',
              currentValue: _selectedPrivacy,
            ),
          ],
        ),
      ),
    );

    if (selected != null && selected != _selectedPrivacy) {
      setState(() => _selectedPrivacy = selected);
    }
  }

  /// Xác nhận trước khi thoát nếu có thay đổi
  Future<bool> _onWillPop() async {
    final hasContent = _contentController.text.trim().isNotEmpty;
    final hasImages = _imageUrls.isNotEmpty || _selectedImages.isNotEmpty;

    // Nếu đang edit hoặc không có nội dung gì thì cho phép thoát
    if (_isEditMode || (!hasContent && !hasImages)) {
      return true;
    }

    // Nếu đang tạo bài mới và có nội dung, hỏi xác nhận
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy bài viết?'),
        content: const Text(
            'Bạn có chắc chắn muốn hủy? Nội dung đang soạn sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục soạn'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Hủy bài viết'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostHeader(
                      isEditMode: _isEditMode,
                      currentUser: _currentUser,
                      isLoadingUser: _isLoadingUser,
                      selectedPrivacy: _selectedPrivacy,
                      onPrivacyTap: _showPrivacySelector,
                    ),
                    const Divider(
                        height: 1, color: AppColors.divider, thickness: 1),
                    _PostContentField(
                      controller: _contentController,
                      isEditMode: _isEditMode,
                    ),
                    if (_imageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                      _ImagePreviewSection(
                        imageUrls: _imageUrls,
                        selectedImages: _selectedImages,
                        onRemoveUrl: _removeUrlImage,
                        onRemoveSelected: _removeSelectedImage,
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _BottomToolbar(
              onImagePick: _pickImages,
              hasImages: _imageUrls.isNotEmpty || _selectedImages.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: AppColors.text),
      ),
      title: Text(
        _isEditMode ? 'Chỉnh sửa bài viết' : 'Tạo bài viết',
        style: AppTextStyles.appBarTitle,
      ),
      centerTitle: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.divider),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOut),
            ),
            child: ElevatedButton(
              onPressed:
                  _isPostButtonEnabled && !_isPosting ? _submitPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPostButtonEnabled
                    ? AppColors.primary
                    : AppColors.hintText,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 0,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(_isEditMode ? 'Lưu' : 'Đăng',
                      style: AppTextStyles.button),
            ),
          ),
        ),
      ],
    );
  }
}

// ===== WIDGET COMPONENTS =====

/// Widget hiển thị header với avatar và tên người dùng
class _PostHeader extends StatelessWidget {
  final bool isEditMode;
  final Map<String, dynamic>? currentUser;
  final bool isLoadingUser;
  final String selectedPrivacy;
  final VoidCallback onPrivacyTap;

  const _PostHeader({
    required this.isEditMode,
    required this.currentUser,
    required this.isLoadingUser,
    required this.selectedPrivacy,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.imagePlaceholder,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 16,
                  child: LinearProgressIndicator(),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  height: 12,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final username = currentUser?['username'] ?? 'Người dùng';
    final avatarUrl = currentUser?['avatarUrl'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const NetworkImage(
                      'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: AppTextStyles.addPostUserName),
                const SizedBox(height: 4),
                _PrivacyButton(
                  selectedPrivacy: selectedPrivacy,
                  onTap: onPrivacyTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút chọn quyền riêng tư (Public/Friends/Private)
class _PrivacyButton extends StatelessWidget {
  final String selectedPrivacy;
  final VoidCallback onTap;

  const _PrivacyButton({
    required this.selectedPrivacy,
    required this.onTap,
  });

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'private':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  String _getPrivacyLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Công khai';
      case 'friends':
        return 'Bạn bè';
      case 'private':
        return 'Riêng tư';
      default:
        return 'Công khai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.privacyButton,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getPrivacyIcon(selectedPrivacy),
                size: 14, color: AppColors.toolbarItem),
            const SizedBox(width: 4),
            Text(_getPrivacyLabel(selectedPrivacy),
                style: AppTextStyles.addPostPrivacy),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: AppColors.toolbarItem),
          ],
        ),
      ),
    );
  }
}

/// Widget nhập nội dung bài viết
class _PostContentField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditMode;

  const _PostContentField({
    required this.controller,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        autofocus: !isEditMode,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'Bạn đang nghĩ gì?',
          hintStyle: AppTextStyles.addPostInputText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.addPostInputText,
      ),
    );
  }
}

/// Widget hiển thị danh sách ảnh đã chọn với layout giống HomePostCard
class _ImagePreviewSection extends StatelessWidget {
  final List<String> imageUrls;
  final List<File> selectedImages;
  final Function(int) onRemoveUrl;
  final Function(int) onRemoveSelected;

  const _ImagePreviewSection({
    required this.imageUrls,
    required this.selectedImages,
    required this.onRemoveUrl,
    required this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = imageUrls.length + selectedImages.length;
    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.postCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageGrid(context, totalCount),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, int totalCount) {
    if (totalCount == 1) {
      // 1 ảnh: Full width, KHÔNG có AspectRatio (giống HomePostCard)
      return _buildSingleImage(context, 0);
    } else if (totalCount == 2) {
      // 2 ảnh: 2 cột bằng nhau với AspectRatio 1:1
      return Row(
        children: [
          Expanded(child: _buildImageItem(context, 0, aspectRatio: 1)),
          const SizedBox(width: 2),
          Expanded(child: _buildImageItem(context, 1, aspectRatio: 1)),
        ],
      );
    } else {
      // 3 ảnh: 1 ảnh lớn bên trái, 2 ảnh nhỏ bên phải với AspectRatio 1:1
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildImageItem(context, 0, aspectRatio: 1),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                _buildImageItem(context, 1, aspectRatio: 1),
                const SizedBox(height: 2),
                _buildImageItem(context, 2, aspectRatio: 1),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSingleImage(BuildContext context, int index) {
    // KHÔNG có AspectRatio - để ảnh hiển thị tự nhiên (giống HomePostCard)
    return _buildImageItem(context, index, aspectRatio: null);
  }

  Widget _buildImageItem(BuildContext context, int index,
      {double? aspectRatio}) {
    Widget imageWidget;
    VoidCallback onRemove;

    if (index < imageUrls.length) {
      final url = imageUrls[index];
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        // QUAN TRỌNG: Chỉ set height khi có aspectRatio
        height: aspectRatio != null ? double.infinity : null,
        errorBuilder: (context, error, stackTrace) => Container(
          height: aspectRatio != null ? double.infinity : 200,
          color: AppColors.imagePlaceholder,
          child: const Icon(Icons.broken_image,
              color: AppColors.subtitle, size: 32),
        ),
      );
      onRemove = () => onRemoveUrl(index);
    } else {
      final fileIndex = index - imageUrls.length;
      final file = selectedImages[fileIndex];
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        // QUAN TRỌNG: Chỉ set height khi có aspectRatio
        height: aspectRatio != null ? double.infinity : null,
      );
      onRemove = () => onRemoveSelected(fileIndex);
    }

    Widget content = Stack(
      fit: aspectRatio != null ? StackFit.expand : StackFit.loose,
      children: [
        imageWidget,
        // Nút xóa ảnh
        Positioned(
          top: 8,
          right: 8,
          child: _RemoveImageButton(onTap: onRemove),
        ),
      ],
    );

    // Thêm GestureDetector để xem fullscreen
    content = GestureDetector(
      onTap: () => _showImageFullscreen(context, index),
      child: content,
    );

    // Chỉ wrap AspectRatio nếu được chỉ định
    if (aspectRatio != null) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: content,
      );
    }

    return content;
  }

  /// Hiển thị ảnh fullscreen với swipe
  void _showImageFullscreen(BuildContext context, int initialIndex) {
    final allImages = <dynamic>[...imageUrls, ...selectedImages];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          images: allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Nút xóa ảnh với hiệu ứng
class _RemoveImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.imageOverlayRemove,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: const Icon(
            Icons.close,
            color: AppColors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Thanh công cụ ở dưới cùng (Thêm ảnh, emoji, v.v.)
class _BottomToolbar extends StatelessWidget {
  final VoidCallback onImagePick;
  final bool hasImages;

  const _BottomToolbar({
    required this.onImagePick,
    required this.hasImages,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Thêm vào bài viết',
                style: AppTextStyles.toolbarItemText,
              ),
            ),
            _ToolbarIconButton(
              icon: Icons.photo_library_outlined,
              color: AppColors.success,
              tooltip: 'Ảnh/Video',
              onTap: onImagePick,
              isActive: hasImages,
            ),
            _ToolbarIconButton(
              icon: Icons.person_add_outlined,
              color: AppColors.primary,
              tooltip: 'Gắn thẻ người khác',
              onTap: () {
                // TODO: Implement tagging
              },
            ),
            _ToolbarIconButton(
              icon: Icons.emoji_emotions_outlined,
              color: AppColors.warning,
              tooltip: 'Cảm xúc/Hoạt động',
              onTap: () {
                // TODO: Implement feeling/activity
              },
            ),
            _ToolbarIconButton(
              icon: Icons.location_on_outlined,
              color: AppColors.danger,
              tooltip: 'Vị trí',
              onTap: () {
                // TODO: Implement location
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút icon trong toolbar
class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? color.withOpacity(0.1) : AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Option trong privacy selector dialog
class _PrivacyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String currentValue;

  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.imagePlaceholder,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.subtitle,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình xem ảnh fullscreen với swipe
class _ImageViewerScreen extends StatefulWidget {
  final List<dynamic> images; // List chứa String (URL) hoặc File
  final int initialIndex;

  const _ImageViewerScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: image is String
                  ? Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        );
                      },
                    )
                  : Image.file(
                      image as File,
                      fit: BoxFit.contain,
                    ),
            ),
          );
        },
      ),
    );
  }
}
