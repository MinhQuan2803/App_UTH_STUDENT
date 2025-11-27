import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import để dùng SVG
import '../config/app_theme.dart';
import '../models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  // Callback cho nút option (3 chấm/setting), nếu null thì không hiện
  final VoidCallback? onOptionTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onOptionTap,
  });

  // Helper: Format ngày đăng
  String _formatDate(dynamic dateInput) {
    try {
      DateTime date;
      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        return 'Vừa xong';
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildThumbnail() {
    String imageUrl = document.getPageUrl(1);
    bool isValidUrl = imageUrl.isNotEmpty && imageUrl.startsWith(RegExp(r'http(s)?://'));

    if (!isValidUrl) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.grey[300]),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[100],
        child: Icon(Icons.broken_image, color: Colors.grey[300]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "vi_VN");
    
    // --- MÀU SẮC & TRẠNG THÁI ---
    Color statusColor;
    String statusText;
    Color statusBg;

    if (document.isFullAccess) {
      statusText = 'Đã sở hữu';
      statusColor = Colors.green[700]!;
      statusBg = Colors.green[50]!;
    } else if (document.price == 0) {
      statusText = 'Miễn phí';
      statusColor = Colors.blue[700]!;
      statusBg = Colors.blue[50]!;
    } else {
      statusText = '${currencyFormat.format(document.price)} đ';
      statusColor = AppColors.primary;
      statusBg = AppColors.primary.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THUMBNAIL
                Hero(
                  tag: 'doc_img_${document.id}',
                  child: Container(
                    width: 90,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildThumbnail(),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
                            ),
                            child: const Text('PDF', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 14),

                // 2. NỘI DUNG CHÍNH
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row: Title + Option Icon (Nếu có)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              document.title,
                              style: const TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: Colors.black87
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Icon Setting (Chỉ hiện nếu onOptionTap != null)
                          if (onOptionTap != null)
                            InkWell(
                              onTap: onOptionTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 8),
                                child: SvgPicture.asset(
                                  AppAssets.iconSetting, // Dùng icon setting từ assets
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),

                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundImage: document.ownerAvatar.isNotEmpty 
                                ? NetworkImage(document.ownerAvatar) 
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: document.ownerAvatar.isEmpty 
                                ? const Icon(Icons.person, size: 12, color: Colors.grey) 
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              document.ownerName,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      
                      // Metadata Row
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(document.createdAt), 
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.description_outlined, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${document.totalPages} trang',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Price Badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}