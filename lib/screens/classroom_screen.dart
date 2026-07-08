import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/classroom_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';

/// 空教室查询页面
class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('空教室查询'),
        centerTitle: true,
      ),
      body: Consumer2<ClassroomProvider, ScheduleProvider>(
        builder: (context, classroomProvider, scheduleProvider, _) {
          return Column(
            children: [
              // 筛选条件区域
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    // 教学楼选择
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('教学楼')),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: classroomProvider.selectedBuilding,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('全部')),
                              ...AppConstants.defaultBuildings.map(
                                (b) => DropdownMenuItem(value: b, child: Text(b)),
                              ),
                            ],
                            onChanged: classroomProvider.setBuilding,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 星期选择
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('星期')),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: classroomProvider.selectedDayOfWeek,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: List.generate(7, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text(AppConstants.dayOfWeekNames[i]),
                              );
                            }),
                            onChanged: (v) {
                              if (v != null) classroomProvider.setDayOfWeek(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 节次选择
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('节次')),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: classroomProvider.selectedStartPeriod,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1-2节')),
                              DropdownMenuItem(value: 3, child: Text('3-4节')),
                              DropdownMenuItem(value: 5, child: Text('5-6节')),
                              DropdownMenuItem(value: 7, child: Text('7-8节')),
                              DropdownMenuItem(value: 9, child: Text('9-10节')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                classroomProvider.setPeriod(v, 2);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 查询按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: classroomProvider.isLoading
                            ? null
                            : () {
                                final token = scheduleProvider.token;
                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('请先导入课表以登录教务系统')),
                                  );
                                  return;
                                }
                                classroomProvider.queryClassrooms(token);
                              },
                        icon: const Icon(Icons.search),
                        label: const Text('查询空教室'),
                      ),
                    ),
                  ],
                ),
              ),

              // 结果列表
              Expanded(
                child: classroomProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : classroomProvider.errorMessage != null
                        ? _buildError(classroomProvider.errorMessage!)
                        : classroomProvider.classrooms.isEmpty
                            ? _buildEmptyHint()
                            : _buildResultList(classroomProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    // 如果错误信息包含 HTML 或过长，显示友好提示
    final displayMessage = message.contains('<') || message.length > 100
        ? '查询失败，请检查:\n1. 是否已导入课表（需先登录教务系统）\n2. 爬虫服务是否正常运行'
        : message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '选择筛选条件后点击查询',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(ClassroomProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '搜索结果 (共 ${provider.classrooms.length} 间)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.classrooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final classroom = provider.classrooms[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.meeting_room, color: Colors.green[600], size: 20),
                ),
                title: Text(
                  '${classroom.building}${classroom.roomNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  classroom.capacity != null && classroom.capacity! > 0
                      ? '容量: ${classroom.capacity}人'
                      : '容量: 未知',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.star_border, size: 20),
                  onPressed: () {
                    // TODO: 收藏教室 (P1)
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
