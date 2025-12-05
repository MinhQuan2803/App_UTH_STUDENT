import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/document_service.dart';
import '../utils/dialog_utils.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentService _docService = DocumentService();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // State Variables
  File? _selectedFile;
  String? _fileName;
  String _privacy = 'public';
  bool _isFree = true;
  bool _autoCreatePost = false; // Checkbox tự động tạo bài post
  bool _isUploading = false;

  final currencyFormat = NumberFormat("#,###", "vi_VN");

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
      ],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        if (_titleController.text.isEmpty) {
          _titleController.text = _fileName!.split('.').first;
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn file tài liệu!'),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      int finalPrice = 0;
      if (!_isFree) {
        String cleanPrice =
            _priceController.text.replaceAll('.', '').replaceAll(',', '');
        finalPrice = int.tryParse(cleanPrice) ?? 0;
      }

      if (_autoCreatePost) {
        // Gọi API upload-with-post (tạo cả document và post)
        await _docService.uploadDocumentWithPost(
          file: _selectedFile!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: finalPrice,
          privacy: _privacy,
        );

        if (mounted) {
          showAppDialog(
            context,
            type: DialogType.success,
            title: 'Thành công',
            message: 'Tài liệu đã được đăng tải và bài viết đã được tạo!',
          );
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, true);
        }
      } else {
        // Gọi API upload thông thường (chỉ tạo document)
        await _docService.uploadDocument(
          file: _selectedFile!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: finalPrice,
          privacy: _privacy,
        );

        if (mounted) {
          showAppDialog(
            context,
            type: DialogType.success,
            title: 'Thành công',
            message: 'Tài liệu đã được đăng tải!',
          );
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        showAppDialog(
          context,
          type: DialogType.error,
          title: 'Lỗi',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, // Màu nền xám nhạt sạch sẽ
      appBar: AppBar(
        title: const Text(
          'Đăng tài liệu',
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. File Upload Area
                    _buildUploadArea(),
                    const SizedBox(height: 12),

                    // 2. Info Fields
                    Text('THÔNG TIN CƠ BẢN',
                        style: AppTextStyles.sectionTitle
                            .copyWith(color: AppColors.subtitle)),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _titleController,
                      label: 'Tiêu đề tài liệu',
                      hint: 'Nhập tiêu đề rõ ràng...',
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Mô tả',
                      hint: 'Giới thiệu ngắn gọn về tài liệu...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // 3. Settings Area
                    Text('CÀI ĐẶT',
                        style: AppTextStyles.sectionTitle
                            .copyWith(color: AppColors.subtitle)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          _buildPriceOption(),
                          if (!_isFree) ...[
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                    height: 1, color: AppColors.divider)),
                            _buildPriceInput(),
                          ],
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: AppColors.divider)),
                          _buildPrivacyDropdown(),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: AppColors.divider)),
                          _buildAutoPostCheckbox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: AppTextStyles.button,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('ĐĂNG TÀI LIỆU'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    bool hasFile = _selectedFile != null;
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasFile ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? AppColors.primary : AppColors.divider,
            width: hasFile ? 1.5 : 1,
            style: hasFile ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasFile ? AppColors.white : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? Icons.check_rounded : Icons.cloud_upload_outlined,
                size: 32,
                color: hasFile ? AppColors.primary : AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _fileName ?? 'Chạm để chọn file (PDF, DOC)',
                textAlign: TextAlign.center,
                style: hasFile
                    ? AppTextStyles.bodyBold.copyWith(color: AppColors.primary)
                    : AppTextStyles.bodyRegular,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintText,
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceOption() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFree = true),
            child: _buildRadioItem('Miễn phí', _isFree),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFree = false),
            child: _buildRadioItem('Có phí', !_isFree),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioItem(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.primary : AppColors.subtitle,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return Row(
      children: [
        const Icon(Icons.monetization_on_outlined,
            color: AppColors.subtitle, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
            decoration: const InputDecoration(
              hintText: 'Nhập số điểm (VD: 100)',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const Text('điểm', style: AppTextStyles.bodyRegular),
      ],
    );
  }

  Widget _buildPrivacyDropdown() {
    return DropdownButtonFormField<String>(
      value: _privacy,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.subtitle),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        prefixIcon:
            Icon(Icons.lock_outline, color: AppColors.subtitle, size: 20),
        prefixIconConstraints: BoxConstraints(minWidth: 32),
      ),
      items: const [
        DropdownMenuItem(
            value: 'public',
            child: Text('Công khai', style: AppTextStyles.bodyRegular)),
        DropdownMenuItem(
            value: 'private',
            child: Text('Riêng tư', style: AppTextStyles.bodyRegular)),
      ],
      onChanged: (val) => setState(() => _privacy = val!),
    );
  }

  Widget _buildAutoPostCheckbox() {
    return InkWell(
      onTap: () => setState(() => _autoCreatePost = !_autoCreatePost),
      child: Row(
        children: [
          const Icon(Icons.post_add, color: AppColors.subtitle, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tự động tạo bài viết',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chia sẻ tài liệu lên trang cá nhân',
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: _autoCreatePost,
              onChanged: (val) => setState(() => _autoCreatePost = val),
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
