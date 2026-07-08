import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../utils/color_helper.dart';
import 'course_card.dart';

/// 课表网格组件（整个 App 最核心的 UI 组件）
class ScheduleGrid extends StatelessWidget {
  final List<CourseSchedule> schedules;
  final Map<String, String> colorMap; // courseId → hex color
  final Map<String, Course> courseMap; // courseId → Course
  final Function(Course, List<CourseSchedule>) onCourseTap;

  static const double _periodHeight = 55.0; // 每节课的高度
  static const double _labelColumnWidth = 36.0; // 节次标签列宽

  const ScheduleGrid({
    super.key,
    required this.schedules,
    required this.colorMap,
    required this.courseMap,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context),
          _buildBody(context),
        ],
      ),
    );
  }

  /// 表头：周一~周五
  Widget _buildHeader(BuildContext context) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五'];

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          const SizedBox(width: _labelColumnWidth, height: 36),
          ...dayNames.map((day) {
            return Expanded(
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 课表主体
  Widget _buildBody(BuildContext context) {
    // 按节次分组（1-12节）
    final maxPeriod = 12;
    final screenWidth = MediaQuery.of(context).size.width;
    final dayColumnWidth = (screenWidth - _labelColumnWidth) / 5;

    return SizedBox(
      height: maxPeriod * _periodHeight,
      child: Stack(
        children: [
          // 背景网格线
          _buildGridLines(maxPeriod, dayColumnWidth),
          // 课程卡片（绝对定位）
          ..._buildCourseCards(context, dayColumnWidth),
        ],
      ),
    );
  }

  /// 背景网格线
  Widget _buildGridLines(int maxPeriod, double dayColumnWidth) {
    return Column(
      children: List.generate(maxPeriod, (i) {
        return Row(
          children: [
            // 节次标签
            Container(
              width: _labelColumnWidth,
              height: _periodHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  right: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
            // 星期列
            ...List.generate(5, (j) {
              return Container(
                width: dayColumnWidth,
                height: _periodHeight,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  /// 课程卡片（绝对定位在网格上方）
  List<Widget> _buildCourseCards(BuildContext context, double dayColumnWidth) {
    // 按 (dayOfWeek, startPeriod) 分组，处理同一格子多个课程的情况
    final grouped = <String, List<CourseSchedule>>{};
    for (final s in schedules) {
      final key = '${s.dayOfWeek}_${s.startPeriod}';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final cards = <Widget>[];

    for (final entry in grouped.entries) {
      final parts = entry.key.split('_');
      final dayOfWeek = int.parse(parts[0]);
      final schedules = entry.value;
      final schedule = schedules.first;

      // 计算位置
      final left = _labelColumnWidth + (dayOfWeek - 1) * dayColumnWidth + 1.5;
      final top = (schedule.startPeriod - 1) * _periodHeight + 1.5;
      final width = dayColumnWidth - 3; // 减去 margin
      final height = schedule.duration * _periodHeight - 3;

      // 获取课程信息和颜色
      final course = courseMap[schedule.courseId];
      final colorHex = colorMap[schedule.courseId] ?? 'FF6B6B';
      final color = Color(ColorHelper.hexToInt(colorHex));

      cards.add(
        Positioned(
          left: left,
          top: top,
          width: width,
          child: CourseCard(
            courseName: course?.name ?? '未知课程',
            location: schedule.location,
            color: color,
            height: height,
            onTap: () {
              if (course != null) {
                // 找到该课程的所有排课
                final allSchedules = <CourseSchedule>[];
                for (final s in this.schedules) {
                  if (s.courseId == course.id) {
                    allSchedules.add(s);
                  }
                }
                onCourseTap(course, allSchedules);
              }
            },
          ),
        ),
      );
    }

    return cards;
  }
}
