import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../providers/app_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_grid.dart';
import '../widgets/week_selector.dart';
import '../widgets/course_detail_sheet.dart';
import '../screens/login_screen.dart';
import '../screens/add_course_screen.dart';

/// 课表主页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟加载，确保 Provider 已经初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    scheduleProvider.loadCachedSchedule(appProvider.semesterId);
  }

  void _showCourseDetail(Course course, List<CourseSchedule> schedules) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final colorHex = scheduleProvider.getCourseColor(course.name);
    final color = Color(int.parse('FF$colorHex', radix: 16));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CourseDetailSheet(
        course: course,
        schedules: schedules,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
        centerTitle: true,
        actions: [
          Consumer<ScheduleProvider>(
            builder: (context, sp, _) => IconButton(
              icon: const Icon(Icons.add),
              tooltip: '手动添加课程',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddCourseScreen()),
                ).then((added) {
                  if (added == true) {
                    _loadData();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 周次选择器（纯展示）
            Consumer<AppProvider>(
              builder: (context, app, _) => WeekSelector(
                currentWeek: app.currentWeek,
                totalWeeks: app.totalWeeks,
                weekDateRange: app.weekDateRange,
              ),
            ),

            // 课表区域（支持左右滑动切换周次）
            Expanded(
              child: Consumer2<ScheduleProvider, AppProvider>(
                builder: (context, scheduleProvider, appProvider, _) {
                  if (scheduleProvider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('加载课表中...'),
                        ],
                      ),
                    );
                  }

                  if (!scheduleProvider.hasData) {
                    return _buildEmptyState();
                  }

                  // 构建 courseMap
                  final courseMap = <String, Course>{};
                  for (final course in scheduleProvider.courses) {
                    courseMap[course.id] = course;
                  }

                  // 获取当前周的排课
                  final weekSchedules = scheduleProvider.getSchedulesForWeek(appProvider.currentWeek);

                  // 如果没有课程但数据不为空，可能还没开学或当前周无课
                  if (weekSchedules.isEmpty && scheduleProvider.courses.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            '第${appProvider.currentWeek}周没有课程安排',
                            style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -300) {
                        // 向左滑 → 下一周
                        appProvider.nextWeek();
                      } else if (details.primaryVelocity! > 300) {
                        // 向右滑 → 上一周
                        appProvider.previousWeek();
                      }
                    },
                    child: ScheduleGrid(
                      schedules: weekSchedules,
                      colorMap: scheduleProvider.colorMap,
                      courseMap: courseMap,
                      onCourseTap: _showCourseDetail,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '还没有课表数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '从教务系统导入或手动添加课程',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((success) {
                if (success == true) {
                  _loadData();
                }
              });
            },
            icon: const Icon(Icons.download),
            label: const Text('从教务系统导入'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddCourseScreen()),
              ).then((added) {
                if (added == true) {
                  _loadData();
                }
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('手动添加课程'),
          ),
        ],
      ),
    );
  }
}
