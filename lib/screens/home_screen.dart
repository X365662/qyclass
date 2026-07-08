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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, app, _) =>
              Text('第${app.currentWeek}周 · 课表'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '手动添加课程',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddCourseScreen()),
              ).then((added) {
                if (added == true) _loadData();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 周次选择器
            Consumer<AppProvider>(
              builder: (context, app, _) => WeekSelector(
                currentWeek: app.currentWeek,
                totalWeeks: app.totalWeeks,
                weekDateRange: app.weekDateRange,
                onPrevious: app.previousWeek,
                onNext: app.nextWeek,
              ),
            ),

            // 课表区域 — GestureDetector 在外层，覆盖所有子状态
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  final app = context.read<AppProvider>();
                  if (details.primaryVelocity! < -300) {
                    app.nextWeek();
                  } else if (details.primaryVelocity! > 300) {
                    app.previousWeek();
                  }
                },
                child: Consumer2<ScheduleProvider, AppProvider>(
                  builder: (context, sp, app, _) {
                    if (sp.isLoading) return _buildLoading(cs);
                    if (!sp.hasData) return _buildEmptyState(cs);

                    final courseMap = <String, Course>{};
                    for (final c in sp.courses) {
                      courseMap[c.id] = c;
                    }

                    final weekSchedules = sp.getSchedulesForWeek(app.currentWeek);

                    if (weekSchedules.isEmpty && sp.courses.isNotEmpty) {
                      return _buildNoCourses(app.currentWeek, cs);
                    }

                    return ScheduleGrid(
                      schedules: weekSchedules,
                      colorMap: sp.colorMap,
                      courseMap: courseMap,
                      onCourseTap: _showCourseDetail,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 16),
          Text('加载课表中...', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildNoCourses(int week, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            '第$week周没有课程安排',
            style: TextStyle(color: cs.onSurface, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '← 左右滑动查看其他周 →',
            style: TextStyle(color: cs.outlineVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            '还没有课表数据',
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '从教务系统导入或手动添加课程',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((success) {
                if (success == true) _loadData();
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
                if (added == true) _loadData();
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
