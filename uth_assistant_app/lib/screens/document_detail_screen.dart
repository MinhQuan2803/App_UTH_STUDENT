import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/dialog_utils.dart';
import 'document_reader_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  final DocumentModel? initialData;

  const DocumentDetailScreen(
      {super.key, required this.documentId, this.initialData});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentService _docService = DocumentService();
  final TransactionService _transService = TransactionService();

  late Future<DocumentModel> _futureDoc;
  bool _isBuying = false;

  // State quản lý trạng thái Yêu thích
  bool _isLiked = false;
  bool _isLikeLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLikeStatus();
  }

  void _loadData() {
    setState(() {
      _futureDoc = _docService.getDocumentDetail(widget.documentId);
    });
  }

  // --- LOGIC TÍNH SỐ TRANG XEM TRƯỚC AN TOÀN ---
  int _calculatePreviewCount(DocumentModel doc) {
    return doc.getSafePreviewPages();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final likedDocs = await _docService.getLikedDocuments(page: 100);
      if (mounted) {
        setState(() {
          _isLiked = likedDocs.any((doc) => doc.id == widget.documentId);
          _isLikeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLikeLoading = false);
      print("Error checking like status: $e");
    }
  }

  Future<void> _handleToggleLike() async {
    setState(() => _isLiked = !_isLiked);
    try {
      final newStatus = await _docService.toggleLike(widget.documentId);
      if (mounted) setState(() => _isLiked = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isLiked ? 'Đã thêm vào Yêu thích ❤️' : 'Đã bỏ Yêu thích'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _isLiked ? AppColors.accent : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiked = !_isLiked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleBuy(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Bạn có chắc chắn muốn mua "${doc.title}" với giá ${doc.price} điểm?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Mua ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBuying = true);

    try {
      await _transService.buyDocument(doc.id);
      if (mounted) {
        showAppDialog(context,
            type: DialogType.success,
            title: 'Thành công',
            message: 'Mua tài liệu thành công!');
        _loadData();
      }
    } catch (e) {
      if (mounted)
        showAppDialog(context,
            type: DialogType.error, title: 'Thất bại', message: e.toString());
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  void _openReader(DocumentModel doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DocumentReaderScreen(document: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentModel>(
        future: _futureDoc,
        initialData: widget.initialData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const SizedBox();

          final doc = snapshot.data!;
          return _buildContent(doc);
        },
      ),
    );
  }

  Widget _buildContent(DocumentModel doc) {
    final currencyFormat = NumberFormat("#,###", "vi_VN");

    // --- TÍNH TOÁN SỐ TRANG XEM TRƯỚC ---
    final int previewPages = _calculatePreviewCount(doc);
    final int remainingPages = doc.totalPages - previewPages;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // 1. App Bar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white, size: 24),
              actions: [
                IconButton(
                  onPressed: _isLikeLoading ? null : _handleToggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.accent : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image - Luôn dùng previewUrl (thumbnail)
                    doc.previewUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: doc.previewUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.6),
                            colorBlendMode: BlendMode.darken,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white24, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.picture_as_pdf,
                                color: Colors.white24, size: 64),
                          ),
                    Center(
                      child: Hero(
                        tag: 'doc_img_${doc.id}',
                        child: Container(
                          height: 180,
                          width: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 15,
                                  offset: Offset(0, 8))
                            ],
                            color: Colors.grey[300],
                            image: doc.previewUrl.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        doc.previewUrl),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) => null,
                                  )
                                : null,
                          ),
                          child: doc.previewUrl.isEmpty
                              ? const Icon(Icons.picture_as_pdf,
                                  size: 48, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Nội dung text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            doc.price == 0
                                ? 'MIỄN PHÍ'
                                : '${currencyFormat.format(doc.price)} điểm',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (doc.isFullAccess)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text('Đã sở hữu',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(doc.title,
                        style: AppTextStyles.heading1.copyWith(fontSize: 22)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: doc.ownerAvatar.isNotEmpty
                              ? NetworkImage(doc.ownerAvatar)
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: doc.ownerAvatar.isEmpty
                              ? const Icon(Icons.person,
                                  size: 16, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(doc.ownerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.description_outlined,
                              '${doc.totalPages} trang', 'Độ dài'),
                          Container(
                              width: 1, height: 30, color: Colors.grey[300]),
                          _buildStatItem(
                              Icons.visibility_outlined, '1.2k', 'Lượt xem'),
                          Container(
                              width: 1, height: 30, color: Colors.grey[300]),
                          _buildStatItem(Icons.picture_as_pdf_outlined, 'PDF',
                              'Định dạng'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Tóm tắt', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      doc.summary.isNotEmpty
                          ? doc.summary
                          : (doc.description.isNotEmpty 
                              ? doc.description 
                              : 'Chưa có tóm tắt cho tài liệu này.'),
                      style: const TextStyle(
                          height: 1.5, color: Color(0xFF5A6472)),
                    ),

                    const SizedBox(height: 24),
                    const Text('Xem trước', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),

                    // Thông báo trạng thái preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: doc.isFullAccess
                            ? Colors.green[50]
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: doc.isFullAccess
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            doc.isFullAccess
                                ? Icons.check_circle_outline
                                : Icons.preview_outlined,
                            color: doc.isFullAccess
                                ? Colors.green
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.isFullAccess
                                  ? 'Bạn có thể xem toàn bộ ${doc.totalPages} trang'
                                  : doc.getPreviewMessage(),
                              style: TextStyle(
                                color: doc.isFullAccess
                                    ? Colors.green[700]
                                    : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 3. LOGIC HIỂN THỊ DANH SÁCH HOẶC THÔNG BÁO KHÔNG CHO XEM
            if (previewPages > 0)
              // TRƯỜNG HỢP: Có trang xem trước (Full access hoặc > 5 trang)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Nếu là xem trước, chỉ hiển thị đúng số lượng previewPages
                    if (index >= previewPages) return null;

                    final pageUrl = doc.getPageUrl(index + 1);

                    // ⚠️ Nếu URL rỗng, hiển thị placeholder
                    if (pageUrl.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                            color: Colors.grey[100],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Không có URL tài liệu',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                          color: Colors.white,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CachedNetworkImage(
                          imageUrl: pageUrl,
                          placeholder: (context, url) => const SizedBox(
                              height: 250,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          errorWidget: (context, url, error) => Container(
                            height: 250,
                            color: Colors.grey[100],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Không thể tải trang này'),
                                ],
                              ),
                            ),
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                  childCount: previewPages,
                ),
              )
            else if (!doc.isFullAccess)
              // TRƯỜNG HỢP: < 3 trang và chưa mua -> Không cho xem trước
              SliverToBoxAdapter(
                child: Container(
                  height: 220,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[50]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline,
                            size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tài liệu có ${doc.totalPages} trang',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          previewPages == 0
                              ? 'Tài liệu ngắn không hỗ trợ xem trước.\nMua để xem toàn bộ nội dung.'
                              : 'Mua tài liệu để mở khóa toàn bộ nội dung.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Giá: ${currencyFormat.format(doc.price)} điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Locked Content Indicator (Nếu chưa mua)
            // Chỉ hiện phần này nếu previewPages > 0 (tức là có xem trước nhưng bị che phần còn lại)
            if (!doc.isFullAccess && previewPages > 0)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Còn $remainingPages trang nữa',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text('Mua tài liệu để xem toàn bộ nội dung',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),

        // 5. Bottom Action Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
          
            ),
            child: SafeArea(
              child: doc.isFullAccess
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.chrome_reader_mode_outlined),
                      label: const Text('ĐỌC NGAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () => _openReader(doc),
                    )
                  : ElevatedButton(
                      onPressed: _isBuying ? null : () => _handleBuy(doc),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isBuying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              'MUA VỚI ${doc.price == 0 ? "MIỄN PHÍ" : "${currencyFormat.format(doc.price)} ĐIỂM"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
