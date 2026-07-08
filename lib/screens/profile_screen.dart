import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

/// 我的页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: Consumer2<AppProvider, ScheduleProvider>(
        builder: (context, app, schedule, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '轻院学子',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${app.semesterName} · 第${app.currentWeek}周',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 学期信息
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('当前学期'),
                      subtitle: Text(app.semesterName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('教学周'),
                      subtitle: Text('第 ${app.currentWeek} / ${app.totalWeeks} 周'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.book_outlined),
                      title: const Text('课程数量'),
                      subtitle: Text('${schedule.courses.length} 门课程'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 操作
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('重新导入课表'),
                      subtitle: const Text('从教务系统更新课表数据'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        if (result == true) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('课表导入成功！')),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('课程颜色设置'),
                      subtitle: const Text('自定义每门课程的颜色'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 颜色设置页面 (P1)
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: const Text('服务器地址'),
                      subtitle: Text(
                        ApiService.baseUrl,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showServerConfigDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('设置'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 设置页面 (P1)
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 关于
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于轻院课表'),
                  subtitle: const Text('v1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '轻院课表',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 轻院课表',
                      children: [
                        const Text('面向华北理工大学轻工学院学生的课程表 App'),
                        const SizedBox(height: 12),
                        const Text('功能特色：'),
                        const Text('• 教务系统一键导入课表'),
                        const Text('• 周视图课表展示'),
                        const Text('• 空教室查询'),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 服务器地址配置对话框
Future<void> _showServerConfigDialog(BuildContext context) async {
  final controller = TextEditingController(text: ApiService.baseUrl);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('服务器地址'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '输入爬虫服务的完整地址\n部署到云端后在此修改',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://xxx.onrender.com/api/v1',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ApiService.resetBaseUrl();
            controller.text = ApiService.baseUrl;
            Navigator.of(ctx).pop();
          },
          child: const Text('重置默认'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final newUrl = controller.text.trim();
            if (newUrl.isNotEmpty) {
              await ApiService.updateBaseUrl(newUrl);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('已保存: $newUrl')),
                );
                Navigator.of(ctx).pop();
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );

  controller.dispose();
}
