import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_notification.dart';

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
  String _selectedFileType = 'PDF'; // Loại file mặc định

  // Danh sách loại file cho demo
  final List<String> _fileTypes = ['PDF', 'DOCX', 'XLSX', 'PPTX'];

  // Giả lập chọn file
  void _simulatePickFile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn loại file'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _fileTypes.map((type) {
              return ListTile(
                leading: Icon(
                  type == 'PDF' ? Icons.picture_as_pdf :
                  type == 'DOCX' ? Icons.description :
                  type == 'XLSX' ? Icons.table_chart :
                  Icons.slideshow,
                  color: AppColors.primary,
                ),
                title: Text('File .$type'),
                onTap: () {
                  setState(() {
                    _selectedFileType = type;
                    _fileName = 'tai-lieu-mau.$type';
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _submit() {
    final price = int.tryParse(_priceController.text);

    if (_titleController.text.isEmpty) {
      CustomNotification.error(context, 'Vui lòng nhập tiêu đề tài liệu');
      return;
    }
    if (_fileName == null) {
      CustomNotification.error(context, 'Vui lòng chọn một file để tải lên');
      return;
    }
    if (price == null) {
      CustomNotification.error(context, 'Vui lòng nhập giá bán hợp lệ (nhập 0 nếu miễn phí)');
      return;
    }
    
    // TODO: Gọi API Upload Document khi có backend
    CustomNotification.success(
      context,
      'Đã đăng bán: $_fileName\nGiá: ${price == 0 ? "Miễn phí" : "$price điểm"}',
    );
    
    // Quay về màn hình trước
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
              onTap: _simulatePickFile,
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
                    Icon(
                      _fileName != null ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Nhấn để chọn loại file',
                      style: _fileName != null 
                             ? AppTextStyles.bodyBold.copyWith(color: AppColors.primary)
                             : AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle),
                      textAlign: TextAlign.center,
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedFileType,
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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