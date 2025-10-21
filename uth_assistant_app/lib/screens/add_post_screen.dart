import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedMajor;
  late Color _selectedColor;
  bool _isPostButtonEnabled = false;
  late AnimationController _animationController;

  final List<String> _majors = [
    'Thông báo chung',
    'Kinh tế Vận tải',
    'Công nghệ thông tin',
    'Logistics',
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = AppColors.postBackgrounds.first;
    _contentController.addListener(_validatePost);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _validatePost() {
    final bool canPost =
        _contentController.text.trim().isNotEmpty && _selectedMajor != null;
    if (canPost != _isPostButtonEnabled) {
      setState(() => _isPostButtonEnabled = canPost);
      if (canPost) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_validatePost);
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildContentCard()],
              ),
            ),
          ),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.headerGradientStart,
              AppColors.headerGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      leading: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy', style: AppTextStyles.appBarButton),
      ),
      title: const Text('Tạo bài viết', style: AppTextStyles.appBarTitleWhite),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: _isPostButtonEnabled
                    ? const LinearGradient(
                        colors: [
                          AppColors.postButtonGradientStart,
                          AppColors.postButtonGradientEnd,
                        ],
                      )
                    : null,
                color: _isPostButtonEnabled
                    ? null
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ElevatedButton(
                onPressed: _isPostButtonEnabled
                    ? () => Navigator.of(context).pop()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text('Đăng', style: AppTextStyles.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _selectedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    'https://tophinhanh.net/wp-content/uploads/2023/11/avatar-hoat-hinh-1.jpg',
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Mai Phương', style: AppTextStyles.postName),
                const Spacer(),
                _buildMajorDropdown(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: null,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Chia sẻ suy nghĩ của bạn...',
                hintStyle: AppTextStyles.addPostHintText,
                border: InputBorder.none,
              ),
              style: AppTextStyles.addPostInputText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _selectedMajor != null
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMajor,
          hint: const Row(
            children: [
              Icon(Icons.label_outline, size: 14, color: AppColors.subtitle),
              SizedBox(width: 4),
              Text('Lĩnh vực', style: AppTextStyles.postMeta),
            ],
          ),
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primary,
            size: 18,
          ),
          items: _majors.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: AppTextStyles.postName.copyWith(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedMajor = newValue;
              _validatePost();
            });
          },
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Chọn màu nền', style: AppTextStyles.bottomToolbarTitle),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppColors.postBackgrounds.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = AppColors.postBackgrounds[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
