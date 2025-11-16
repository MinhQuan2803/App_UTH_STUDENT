import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/document_list_item.dart';
import '../widgets/simple_wave_header.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // DỮ LIỆU MẪU - Thay thế cho API
  final List<Map<String, dynamic>> _mockAllDocuments = [
    {
      'fileType': 'PDF',
      'title': 'Đề cương môn Giải tích 1',
      'uploader': 'Nguyễn Văn A',
      'price': 50,
    },
    {
      'fileType': 'DOCX',
      'title': 'Bài tập lớn Lập trình Web',
      'uploader': 'Trần Thị B',
      'price': 0,
    },
    {
      'fileType': 'PDF',
      'title': 'Slide bài giảng Cơ sở dữ liệu',
      'uploader': 'Lê Văn C',
      'price': 100,
    },
    {
      'fileType': 'XLSX',
      'title': 'Bảng điểm mẫu môn Xác suất',
      'uploader': 'Phạm Thị D',
      'price': 0,
    },
    {
      'fileType': 'PDF',
      'title': 'Đề thi giữa kỳ Toán rời rạc',
      'uploader': 'Hoàng Văn E',
      'price': 75,
    },
    {
      'fileType': 'DOCX',
      'title': 'Luận văn tốt nghiệp mẫu',
      'uploader': 'Võ Thị F',
      'price': 200,
    },
    {
      'fileType': 'PDF',
      'title': 'Tài liệu ôn thi Cấu trúc dữ liệu',
      'uploader': 'Đặng Văn G',
      'price': 0,
    },
    {
      'fileType': 'PDF',
      'title': 'Đề cương chi tiết môn OOP',
      'uploader': 'Bùi Thị H',
      'price': 150,
    },
  ];

  final List<Map<String, dynamic>> _mockMyDocuments = [
    {
      'fileType': 'PDF',
      'title': 'Bài giảng của tôi - Lập trình Python',
      'uploader': 'Tôi',
      'price': 80,
    },
    {
      'fileType': 'DOCX',
      'title': 'Bài tập nhóm môn AI',
      'uploader': 'Tôi',
      'price': 0,
    },
  ];

  final List<Map<String, dynamic>> _mockLikedDocuments = [
    {
      'fileType': 'PDF',
      'title': 'Đề cương môn Giải tích 1',
      'uploader': 'Nguyễn Văn A',
      'price': 50,
    },
    {
      'fileType': 'PDF',
      'title': 'Slide bài giảng Cơ sở dữ liệu',
      'uploader': 'Lê Văn C',
      'price': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Không cần gọi API - đã có dữ liệu mẫu
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SỬA LỖI: Bỏ Stack và Scaffold, dùng Column
    return Column(
      children: [
        // Header (Giữ nguyên SimpleWaveHeader của bạn)
        const SimpleWaveHeader(
          title: 'Tài liệu học tập',
        ),
        // TabBar
        Container(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.subtitle,
            labelStyle: AppTextStyles.tabLabel,
            indicatorWeight: 3.0,
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Của tôi'),
              Tab(text: 'Đã thích'),
            ],
          ),
        ),
        // Nội dung Tab
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDocumentList(_mockAllDocuments), // Tab 1: Tất cả
              _buildDocumentList(_mockMyDocuments), // Tab 2: Của tôi
              _buildDocumentList(_mockLikedDocuments), // Tab 3: Đã thích
            ],
          ),
        ),
      ],
    );
    // BỎ: Nút FAB (đã được MainScreen quản lý)
  }

  // Hiển thị danh sách tài liệu từ dữ liệu mẫu
  Widget _buildDocumentList(List<Map<String, dynamic>> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear,
                size: 60, color: AppColors.subtitle.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Chưa có tài liệu nào',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyRegular.copyWith(color: AppColors.subtitle),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: () {
              // TODO: Xử lý khi nhấn vào tài liệu
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã chọn: ${doc['title']}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: DocumentListItem(
              fileType: doc['fileType'] ?? 'PDF',
              title: doc['title'] ?? 'Không có tiêu đề',
              uploader: doc['uploader'] ?? 'Không rõ',
              price: doc['price'] ?? 0,
            ),
          ),
        );
      },
    );
  }
}
