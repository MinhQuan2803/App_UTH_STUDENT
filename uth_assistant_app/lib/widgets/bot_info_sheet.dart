import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class BotInfoSheet extends StatelessWidget {
  const BotInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        AppAssets.iconRobot,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UTH Assistant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Trợ lý ảo thông minh',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'Giới thiệu',
                      content:
                          'UTH Assistant là trợ lý ảo thông minh được phát triển '
                          'để hỗ trợ sinh viên và giảng viên Đại học Giao thông Vận tải '
                          'TP.HCM tra cứu thông tin nhanh chóng và chính xác.',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Tính năng',
                      content: '• Trả lời câu hỏi về học vụ, đào tạo\n'
                          '• Tra cứu thông báo, lịch học\n'
                          '• Hướng dẫn quy trình, thủ tục\n'
                          '• Cung cấp liên kết đến tài liệu chính thức\n'
                          '• Gợi ý câu hỏi liên quan',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.help_outline,
                      title: 'Hướng dẫn sử dụng',
                      content: '1. Nhập câu hỏi vào ô chat bên dưới\n'
                          '2. Nhấn nút gửi hoặc Enter để gửi câu hỏi\n'
                          '3. Đọc câu trả lời từ UTH Assistant\n'
                          '4. Nhấn vào liên kết để xem thêm chi tiết\n'
                          '5. Chọn câu hỏi gợi ý để tiếp tục hội thoại',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Mẹo sử dụng',
                      content: '• Đặt câu hỏi rõ ràng, cụ thể\n'
                          '• Sử dụng từ khóa chính xác (VD: "đăng ký học phần", "học phí")\n'
                          '• Kiểm tra liên kết được cung cấp để biết thêm chi tiết\n'
                          '• Thử các câu hỏi gợi ý để khám phá thêm thông tin',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.verified_user_outlined,
                      title: 'Lưu ý',
                      content:
                          '• Thông tin được cập nhật từ nguồn chính thức của trường\n'
                          '• Luôn kiểm tra thông báo mới nhất trên website nhà trường\n'
                          '• Liên hệ phòng ban liên quan nếu cần hỗ trợ trực tiếp',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
