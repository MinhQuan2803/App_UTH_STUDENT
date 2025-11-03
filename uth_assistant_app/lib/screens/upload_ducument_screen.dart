import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
// import 'package:file_picker/file_picker.dart'; // Sẽ cần package này

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _fileName;

  // TODO: Tích hợp logic chọn file
  /*
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    }
  }
  */

  void _showErrorSnackBar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text(message), backgroundColor: AppColors.danger,
     ));
  }

  void _submit() {
    final price = int.tryParse(_priceController.text);

    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập tiêu đề tài liệu');
      return;
    }
    if (_fileName == null) {
      _showErrorSnackBar('Vui lòng chọn một file để tải lên');
      return;
    }
     if (price == null) {
      _showErrorSnackBar('Vui lòng nhập giá bán hợp lệ (nhập 0 nếu miễn phí)');
      return;
    }
    
    // TODO: Gọi API Upload Document
    print('Đăng bán: $_fileName, Tiêu đề: ${_titleController.text}, Giá: $price');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng bán Tài liệu', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        elevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ô chọn file
            GestureDetector(
              // onTap: _pickFile,
              onTap: () {
                // Tạm thời giả lập đã chọn file
                 setState(() => _fileName = 'de-cuong-giai-tich.pdf');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Nhấn để chọn file (PDF, DOCX, PPTX...)',
                      style: _fileName != null 
                             ? AppTextStyles.bodyBold.copyWith(color: AppColors.primary)
                             : AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Ô nhập liệu
            CustomTextField(
              controller: _titleController,
              hintText: 'Tiêu đề tài liệu *',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Mô tả (ví dụ: môn học, giảng viên...)',
              maxLines: 4, // Cho phép nhập nhiều dòng
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              hintText: 'Đặt giá (Điểm UTH) * (Nhập 0 nếu miễn phí)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Chỉ cho nhập số
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Đăng bán',
              onPressed: _submit,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}
