import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../services/profile_service.dart';
import '../utils/dialog_utils.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _realnameController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _realnameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi',
          message: 'Không thể chọn ảnh: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final realname = _realnameController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await _profileService.completeProfile(
        realname: realname,
        avatarFile: _selectedImage,
      );

      if (mounted) {
        await showAppDialog(
          context,
          type: DialogType.success,
          title: 'Hoàn thành!',
          message: 'Hồ sơ của bạn đã được cập nhật thành công',
        );

        // Navigate sau khi dialog đóng
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Khi nhấn nút back hệ thống, quay về login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () {
              // Quay về màn hình login
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
          title: Text(
            'Hoàn thiện hồ sơ',
            style: AppTextStyles.heading1.copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppAssets.paddingXLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Avatar picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Chọn ảnh',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tùy chọn (Có thể bỏ qua)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Input tên thật
                  TextFormField(
                    controller: _realnameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên *',
                      hintText: 'Nhập tên đầy đủ của bạn',
                      hintStyle: AppTextStyles.hintText,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppAssets.borderRadiusLarge,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppAssets.borderRadiusLarge,
                        ),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppAssets.borderRadiusLarge,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                    ),
                    style: AppTextStyles.bodyRegular.copyWith(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên thật';
                      }
                      if (value.trim().length < 2) {
                        return 'Tên phải có ít nhất 2 ký tự';
                      }
                      if (value.trim().length > 100) {
                        return 'Tên không được quá 100 ký tự';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // Nút xác nhận
                  SizedBox(
                    width: double.infinity,
                    height: AppAssets.buttonHeightLarge,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppAssets.borderRadiusLarge,
                          ),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Hoàn thành',
                              style: AppTextStyles.button,
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lưu ý
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
