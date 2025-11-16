import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_notification.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.currentUser['username'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.currentUser['bio'] ?? '',
    );

    // Lắng nghe thay đổi
    _usernameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasUsernameChanged =
        _usernameController.text != (widget.currentUser['username'] ?? '');
    final hasBioChanged =
        _bioController.text != (widget.currentUser['bio'] ?? '');
    final hasImageChanged = _selectedImage != null;

    setState(() {
      _hasChanges = hasUsernameChanged || hasBioChanged || hasImageChanged;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Hiển thị dialog chọn nguồn ảnh
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn ảnh từ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();

        // Kiểm tra kích thước file (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (!mounted) return;
          CustomNotification.error(
            context,
            'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.',
          );
          return;
        }

        setState(() {
          _selectedImage = imageFile;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      CustomNotification.error(
        context,
        'Không thể chọn ảnh. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Cập nhật avatar nếu có
      if (_selectedImage != null) {
        print('📸 Uploading avatar...');
        print('Image path: ${_selectedImage!.path}');

        final result = await _profileService.updateAvatar(
          _selectedImage!.path, // Truyền path thay vì bytes
        );

        print('✓ Avatar upload result: $result');
      }

      // 2. Cập nhật thông tin profile (username, bio)
      final username = _usernameController.text.trim();
      final bio = _bioController.text.trim();

      if (username != widget.currentUser['username'] ||
          bio != (widget.currentUser['bio'] ?? '')) {
        print('📝 Updating profile details...');
        await _profileService.updateProfileDetails(
          username: username,
          bio: bio.isEmpty ? null : bio,
        );
        print('✓ Profile details updated');
      }

      if (!mounted) return;

      // Xóa cache và quay lại
      ProfileService.clearCache();

      CustomNotification.success(
        context,
        'Cập nhật hồ sơ thành công!',
      );

      // Quay lại và báo hiệu cần refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      print('❌ Error updating profile: $e');

      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Xử lý lỗi cụ thể
      if (errorMessage.contains('Username này đã được sử dụng')) {
        errorMessage = 'Username này đã có người sử dụng';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else if (errorMessage.contains('File')) {
        errorMessage = 'Lỗi upload ảnh. Vui lòng thử lại.';
      }

      print('Error message to show: $errorMessage');

      CustomNotification.error(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.currentUser['avatarUrl'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Chỉnh sửa hồ sơ',
        actions: [
          if (_hasChanges && !_isLoading)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar section
                    _buildAvatarSection(currentAvatarUrl),
                    const SizedBox(height: 32),

                    // Username field
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'Nhập username của bạn',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username không được để trống';
                        }
                        if (value.trim().length < 3) {
                          return 'Username phải có ít nhất 3 ký tự';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Username chỉ chứa chữ, số và dấu gạch dưới';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    _buildTextField(
                      controller: _bioController,
                      label: 'Tiểu sử',
                      hint: 'Viết vài dòng về bản thân...',
                      icon: Icons.edit_note,
                      maxLines: 4,
                      maxLength: 200,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'Tiểu sử không được quá 200 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: Opacity(
                        opacity: _hasChanges ? 1.0 : 0.5,
                        child: CustomButton(
                          text: 'Lưu thay đổi',
                          onPressed: () {
                            if (_hasChanges) {
                              _saveChanges();
                            }
                          },
                          isPrimary: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarSection(String? currentAvatarUrl) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                        ? Image.network(
                            currentAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar()),
              ),
            ),
            // Edit button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Nhấn vào camera để đổi ảnh',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: AppColors.primary.withOpacity(0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accent,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
