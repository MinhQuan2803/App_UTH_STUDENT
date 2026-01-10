import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../widgets/document_card.dart';
import '../services/document_service.dart';
import '../models/document_model.dart';
import 'document_detail_screen.dart';
import 'upload_document_screen.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final DocumentService _documentService = DocumentService();
  final TextEditingController _searchController = TextEditingController();

  // State Lists
  List<DocumentModel> _publicDocs = [];
  List<DocumentModel> _purchasedDocs = [];
  List<DocumentModel> _uploadedDocs = [];
  List<DocumentModel> _likedDocs = [];

  // Loading States
  bool _loadingPublic = true;
  bool _loadingPurchased = false;
  bool _loadingUploaded = false;
  bool _loadingLiked = false;

  String _searchKeyword = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });

    _loadPublicDocs();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        if (_purchasedDocs.isEmpty) _loadPurchasedDocs();
        break;
      case 2:
        if (_uploadedDocs.isEmpty) _loadUploadedDocs();
        break;
      case 3:
        if (_likedDocs.isEmpty) _loadLikedDocs();
        break;
    }
  }

  // --- API CALLS ---
  Future<void> _loadPublicDocs() async {
    setState(() => _loadingPublic = true);
    try {
      final docs = await _documentService.getPublicDocuments();
      if (mounted) setState(() => _publicDocs = docs);
    } catch (e) {/*...*/} finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  Future<void> _loadPurchasedDocs() async {
    setState(() => _loadingPurchased = true);
    try {
      final docs = await _documentService.getPurchasedDocuments();
      if (mounted) setState(() => _purchasedDocs = docs);
    } catch (e) {/*...*/} finally {
      if (mounted) setState(() => _loadingPurchased = false);
    }
  }

  Future<void> _loadUploadedDocs() async {
    setState(() => _loadingUploaded = true);
    try {
      final docs = await _documentService.getMyUploadedDocuments();
      if (mounted) setState(() => _uploadedDocs = docs);
    } catch (e) {/*...*/} finally {
      if (mounted) setState(() => _loadingUploaded = false);
    }
  }

  Future<void> _loadLikedDocs() async {
    setState(() => _loadingLiked = true);
    try {
      final docs = await _documentService.getLikedDocuments();
      if (mounted) setState(() => _likedDocs = docs);
    } catch (e) {/*...*/} finally {
      if (mounted) setState(() => _loadingLiked = false);
    }
  }

  // --- PUBLIC METHOD: Refresh current tab ---
  void refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadPublicDocs();
        break;
      case 1:
        _loadPurchasedDocs();
        break;
      case 2:
        _loadUploadedDocs();
        break;
      case 3:
        _loadLikedDocs();
        break;
    }
  }

  // --- ACTIONS (DELETE & EDIT) ---

  // Hiển thị Menu Sửa/Xóa
  void _showDocumentOptions(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Quản lý tài liệu',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              const SizedBox(height: 10),

              // Nút Chỉnh sửa
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Chỉnh sửa thông tin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(doc);
                },
              ),

              // Nút Xóa
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Xóa tài liệu',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(doc);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Dialog Xóa
  void _confirmDelete(DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa tài liệu "${doc.title}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Gọi API Xóa
                await _documentService.deleteDocument(doc.id);
                // Xóa khỏi list local
                setState(() {
                  _uploadedDocs.removeWhere((d) => d.id == doc.id);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã xóa tài liệu thành công'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog Sửa (Tiêu đề, Giá & Privacy)
  void _showEditDialog(DocumentModel doc) {
    final titleCtrl = TextEditingController(text: doc.title);
    final priceCtrl = TextEditingController(text: doc.price.toString());
    // Mặc định chọn theo doc hiện tại nếu có field privacy, nếu không thì default 'public'
    String selectedPrivacy = 'public';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cập nhật thông tin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Tiêu đề tài liệu'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giá bán (Điểm)',
                          hintText: 'Nhập 0 để miễn phí'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPrivacy,
                      decoration:
                          const InputDecoration(labelText: 'Quyền riêng tư'),
                      items: const [
                        DropdownMenuItem(
                            value: 'public', child: Text('Công khai')),
                        DropdownMenuItem(
                            value: 'private', child: Text('Riêng tư')),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedPrivacy = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Huỷ')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      // FIX: Làm sạch chuỗi giá tiền (bỏ dấu chấm, phẩy) trước khi parse
                      String cleanPrice = priceCtrl.text
                          .replaceAll('.', '')
                          .replaceAll(',', '');
                      int newPrice = int.tryParse(cleanPrice) ?? doc.price;

                      await _documentService.updateDocument(
                          doc.id, titleCtrl.text, selectedPrivacy, newPrice);
                      _loadUploadedDocs(); // Reload lại list
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Cập nhật thành công'),
                              backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Lỗi: ${e.toString()}'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child:
                      const Text('Lưu', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<DocumentModel> _filterDocs(List<DocumentModel> docs) {
    if (_searchKeyword.isEmpty) return docs;
    return docs
        .where((doc) => doc.title.toLowerCase().contains(_searchKeyword))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Phải gọi để AutomaticKeepAliveClientMixin hoạt động
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Status bar text màu đen cho nền sáng
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm tài liệu...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
              suffixIcon: _searchKeyword.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.subtitle,
          labelStyle: AppTextStyles.bodyBold,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Khám phá'),
            Tab(text: 'Tủ sách'),
            Tab(text: 'Đã đăng'),
            Tab(text: 'Yêu thích'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocList(_publicDocs, _loadingPublic, _loadPublicDocs,
              'Không tìm thấy tài liệu',
              isEditable: false),
          _buildDocList(_purchasedDocs, _loadingPurchased, _loadPurchasedDocs,
              'Tủ sách trống',
              isEditable: false),
          _buildDocList(_uploadedDocs, _loadingUploaded, _loadUploadedDocs,
              'Chưa đăng tài liệu nào',
              isEditable: true),
          _buildDocList(
              _likedDocs, _loadingLiked, _loadLikedDocs, 'Chưa có yêu thích',
              isEditable: false),
        ],
      ),
    );
  }

  Widget _buildDocList(List<DocumentModel> originalDocs, bool isLoading,
      Future<void> Function() onRefresh, String emptyMsg,
      {required bool isEditable}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filteredDocs = _filterDocs(originalDocs);

    if (filteredDocs.isEmpty) {
      String msg = originalDocs.isEmpty
          ? emptyMsg
          : 'Không có kết quả "$_searchKeyword"';
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(msg, style: TextStyle(color: Colors.grey[500])),
              TextButton(onPressed: onRefresh, child: const Text('Tải lại'))
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          return DocumentCard(
            document: doc,
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentDetailScreen(
                    documentId: doc.id,
                    initialData: doc,
                  ),
                ),
              );
              // Chỉ reload khi có thay đổi (ví dụ: đã mua, đã xóa, đã like)
              if (shouldRefresh == true) {
                onRefresh();
              }
            },
            onOptionTap: isEditable ? () => _showDocumentOptions(doc) : null,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
