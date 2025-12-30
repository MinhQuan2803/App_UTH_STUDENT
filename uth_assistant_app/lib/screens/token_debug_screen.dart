import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Debug screen để kiểm tra token status và test refresh
/// CHỈ SỬ DỤNG ĐỂ DEBUG, XÓA HOẶC ẨN TRONG PRODUCTION
class TokenDebugScreen extends StatefulWidget {
  const TokenDebugScreen({super.key});

  @override
  State<TokenDebugScreen> createState() => _TokenDebugScreenState();
}

class _TokenDebugScreenState extends State<TokenDebugScreen> {
  final AuthService _authService = AuthService();

  String _accessToken = '';
  String _refreshToken = '';
  String _tokenStatus = '';
  Duration _remainingTime = Duration.zero;
  bool _isExpired = false;
  Map<String, dynamic> _decodedToken = {};

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    try {
      final accessToken = await _authService.getToken();
      final refreshToken = await _authService.getRefreshToken();

      if (accessToken != null) {
        final decoded = JwtDecoder.decode(accessToken);
        final remaining = JwtDecoder.getRemainingTime(accessToken);
        final expired = JwtDecoder.isExpired(accessToken);

        setState(() {
          _accessToken = accessToken.substring(0, 50) + '...';
          _refreshToken = refreshToken?.substring(0, 50) ?? 'N/A';
          _decodedToken = decoded;
          _remainingTime = remaining;
          _isExpired = expired;

          if (expired) {
            _tokenStatus = '❌ Token đã hết hạn';
          } else if (remaining.inSeconds < 120) {
            _tokenStatus = '⚠️ Token sắp hết hạn (< 2 phút)';
          } else {
            _tokenStatus = '✅ Token còn hạn';
          }
        });
      } else {
        setState(() {
          _tokenStatus = '❌ Không có token';
        });
      }
    } catch (e) {
      setState(() {
        _tokenStatus = '❌ Lỗi: $e';
      });
    }
  }

  Future<void> _testRefreshToken() async {
    setState(() {
      _tokenStatus = '🔄 Đang refresh...';
    });

    try {
      final result = await _authService.refreshAccessToken();

      switch (result) {
        case RefreshResult.success:
          setState(() {
            _tokenStatus = '✅ Refresh thành công!';
          });
          await _loadTokenInfo();
          break;
        case RefreshResult.networkError:
          setState(() {
            _tokenStatus = '⚠️ Lỗi mạng (session được giữ)';
          });
          break;
        case RefreshResult.failed:
          setState(() {
            _tokenStatus = '❌ Refresh thất bại (sẽ logout)';
          });
          break;
      }
    } catch (e) {
      setState(() {
        _tokenStatus = '❌ Exception: $e';
      });
    }
  }

  Future<void> _testGetValidToken() async {
    setState(() {
      _tokenStatus = '🔄 Đang lấy valid token...';
    });

    try {
      final token = await _authService.getValidToken();

      if (token != null) {
        setState(() {
          _tokenStatus = '✅ getValidToken() success';
        });
        await _loadTokenInfo();
      } else {
        setState(() {
          _tokenStatus = '❌ getValidToken() trả về null';
        });
      }
    } catch (e) {
      setState(() {
        _tokenStatus = '❌ Exception: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Status',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tokenStatus,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Token Info
            _buildInfoCard(
              'Thông Tin Token',
              [
                _buildInfoRow('Còn lại', _formatDuration(_remainingTime)),
                _buildInfoRow('Đã hết hạn', _isExpired ? 'Có' : 'Không'),
                _buildInfoRow('User ID', _decodedToken['userId'] ?? 'N/A'),
                _buildInfoRow('Username', _decodedToken['username'] ?? 'N/A'),
              ],
            ),

            const SizedBox(height: 16),

            // Access Token
            _buildInfoCard(
              'Access Token',
              [
                Text(
                  _accessToken.isNotEmpty ? _accessToken : 'Không có token',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Refresh Token
            _buildInfoCard(
              'Refresh Token',
              [
                Text(
                  _refreshToken,
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadTokenInfo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _testRefreshToken,
                  icon: const Icon(Icons.sync),
                  label: const Text('Test Refresh Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _testGetValidToken,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Test getValidToken()'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _authService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Force Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Debug Mode',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Token < 2 phút → App tự động refresh\n'
                    '• Network error → Giữ session\n'
                    '• Refresh failed → Auto logout\n'
                    '• XÓA screen này trong production!',
                    style: AppTextStyles.bodyRegular.copyWith(
                      fontSize: 12,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.subtitle,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyBold,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_tokenStatus.contains('✅')) return Colors.green;
    if (_tokenStatus.contains('❌')) return Colors.red;
    if (_tokenStatus.contains('⚠️')) return Colors.orange;
    if (_tokenStatus.contains('🔄')) return Colors.blue;
    return AppColors.primary;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày ${duration.inHours % 24} giờ';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ ${duration.inMinutes % 60} phút';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} phút ${duration.inSeconds % 60} giây';
    } else {
      return '${duration.inSeconds} giây';
    }
  }
}
