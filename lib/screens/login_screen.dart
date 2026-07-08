import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../providers/schedule_provider.dart';
import '../providers/app_provider.dart';

/// 教务系统登录页面 — 已接入真实爬虫 API
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _apiService = ApiService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _captchaImageBase64;
  String? _captchaId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 页面打开时自动获取验证码
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCaptcha());
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _getCaptcha() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _captchaImageBase64 = null;
    });

    try {
      final result = await _apiService.getCaptcha();
      setState(() {
        _captchaId = result['captcha_id']?.toString();
        _captchaImageBase64 = result['image_base64']?.toString();
        _captchaController.clear();
        _isLoading = false;
      });
    } on DioException catch (e) {
      String msg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          msg = '连接超时，请检查网络或确认爬虫服务已启动';
          break;
        case DioExceptionType.connectionError:
          msg = '无法连接到服务器，请确认:\n'
              '1. 电脑已启动爬虫服务 (python scraper/main.py)\n'
              '2. 手机和电脑在同一 WiFi\n'
              '3. 服务器地址: ${ApiService.baseUrl}';
          break;
        case DioExceptionType.badResponse:
          msg = '服务器错误 (${e.response?.statusCode})，请稍后重试';
          break;
        default:
          msg = '获取验证码失败: ${e.message}';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取验证码失败: 请检查网络连接';
        _isLoading = false;
      });
    }
  }

  Future<void> _importSchedule() async {
    // 参数校验
    if (_studentIdController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = '请输入学号和密码');
      return;
    }
    if (_captchaController.text.isEmpty) {
      setState(() => _errorMessage = '请输入验证码');
      return;
    }
    if (_captchaId == null) {
      setState(() => _errorMessage = '验证码已过期，请点击图片刷新');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduleProvider = context.read<ScheduleProvider>();
      final appProvider = context.read<AppProvider>();

      final success = await scheduleProvider.importFromAcademicSystem(
        studentId: _studentIdController.text.trim(),
        password: _passwordController.text,
        captchaId: _captchaId!,
        captchaCode: _captchaController.text.trim(),
        semesterId: appProvider.semesterId,
      );

      if (!mounted) return;

      if (success) {
        // 保存学号（方便下次自动填入）
        // TODO: flutter_secure_storage 保存凭证
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = scheduleProvider.errorMessage ?? '导入失败，请重试';
          _isLoading = false;
        });
        // 验证码错误时刷新
        if (_errorMessage?.contains('验证码') == true) {
          _getCaptcha();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '导入失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明文字
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '请输入你的教务系统账号密码，\n我们将从教务系统导入你的课表',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 学号
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '学号',
                hintText: '请输入学号',
                prefixIcon: Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 密码
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入教务系统密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),

            // 验证码
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captchaController,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      hintText: '输入验证码',
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 验证码图片（点击刷新）
                GestureDetector(
                  onTap: _isLoading ? null : _getCaptcha,
                  child: Container(
                    width: 160,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildCaptchaWidget(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 错误提示
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 导入按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _importSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('导入课表', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 12),

            // 刷新验证码
            TextButton.icon(
              onPressed: _isLoading ? null : _getCaptcha,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('换一张验证码'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建验证码显示区域
  Widget _buildCaptchaWidget() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_captchaImageBase64 != null && _captchaImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_captchaImageBase64!);
        if (bytes.isEmpty) {
          return _buildCaptchaPlaceholder();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.memory(bytes, width: 160, height: 60, fit: BoxFit.cover),
        );
      } catch (_) {
        // base64 解码失败，重置并显示占位
        _captchaImageBase64 = null;
        return _buildCaptchaPlaceholder();
      }
    }

    return _buildCaptchaPlaceholder();
  }

  Widget _buildCaptchaPlaceholder() {
    return Center(
      child: Text(
        '点击获取\n验证码',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.blue[600]),
      ),
    );
  }
}
