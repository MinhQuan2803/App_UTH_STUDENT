import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';
import '../widgets/document_list_item.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CẬP NHẬT: Sử dụng Stack để đặt nút Tải lên bên trên nội dung
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Tài liệu học tập', style: AppTextStyles.appBarTitle),
                    ),
                    TabBar(
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentList(),
                  const Center(child: Text('Tài liệu của bạn sẽ hiển thị ở đây')),
                  const Center(child: Text('Các tài liệu đã thích sẽ hiển thị ở đây')),
                ],
              ),
            ),
          ],
        ),
        // Nút "Tải lên" được tích hợp trực tiếp vào màn hình
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Logic tải lên tài liệu
            },
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: SvgPicture.asset(AppAssets.iconUpload, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
            label: const Text('Tải lên', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding để FAB không che
      children: const [
        DocumentListItem(
          fileType: 'PDF',
          title: 'Đề cương Kinh tế Vận tải',
          uploader: 'Tải lên bởi: Lê Nguyễn',
        ),
        SizedBox(height: 12),
        DocumentListItem(
          fileType: 'DOCX',
          title: 'Bài tập lớn Cấu trúc dữ liệu',
          uploader: 'Tải lên bởi: Trần Anh',
        ),
        SizedBox(height: 12),
        DocumentListItem(
          fileType: 'XLSX',
          title: 'Tổng hợp công thức Excel',
          uploader: 'Tải lên bởi: Mai Phương',
        ),
      ],
    );
  }
}

