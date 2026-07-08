import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../utils/color_helper.dart';
import 'course_card.dart';

/// 课表网格组件
class ScheduleGrid extends StatelessWidget {
  final List<CourseSchedule> schedules;
  final Map<String, String> colorMap;
  final Map<String, Course> courseMap;
  final Function(Course, List<CourseSchedule>) onCourseTap;

  static const double _periodHeight = 55.0;
  static const double _labelColumnWidth = 36.0;

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

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday; // 1=Mon

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(25),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _labelColumnWidth, height: 38),
          ...List.generate(5, (i) {
            final isToday = (i + 1 == today);
            return Expanded(
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        color: cs.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  ['周一', '周二', '周三', '周四', '周五'][i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final maxPeriod = 12;
    final screenWidth = MediaQuery.of(context).size.width;
    final dayColumnWidth = (screenWidth - _labelColumnWidth) / 5;

    return SizedBox(
      height: maxPeriod * _periodHeight,
      child: Stack(
        children: [
          _buildGridLines(context, maxPeriod, dayColumnWidth),
          ..._buildCourseCards(context, dayColumnWidth),
        ],
      ),
    );
  }

  Widget _buildGridLines(
      BuildContext context, int maxPeriod, double dayColumnWidth) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.outlineVariant.withAlpha(60);

    return Column(
      children: List.generate(maxPeriod, (i) {
        final isEven = i % 2 == 0;
        return Row(
          children: [
            // 节次标签
            Container(
              width: _labelColumnWidth,
              height: _periodHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEven
                    ? cs.surfaceContainerLowest
                    : cs.surfaceContainerHighest.withAlpha(50),
                border: Border(
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 星期列
            ...List.generate(5, (j) {
              return Container(
                width: dayColumnWidth,
                height: _periodHeight,
                decoration: BoxDecoration(
                  color: isEven
                      ? cs.surfaceContainerLowest.withAlpha(60)
                      : null,
                  border: Border(
                    right: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  List<Widget> _buildCourseCards(BuildContext context, double dayColumnWidth) {
    final grouped = <String, List<CourseSchedule>>{};
    for (final s in schedules) {
      final key = '${s.dayOfWeek}_${s.startPeriod}';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final cards = <Widget>[];

    for (final entry in grouped.entries) {
      final parts = entry.key.split('_');
      final dayOfWeek = int.parse(parts[0]);
      final schedule = entry.value.first;

      final left =
          _labelColumnWidth + (dayOfWeek - 1) * dayColumnWidth + 1.5;
      final top = (schedule.startPeriod - 1) * _periodHeight + 1.5;
      final width = dayColumnWidth - 3;
      final height = schedule.duration * _periodHeight - 3;

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
                final allSchedules = <CourseSchedule>[];
                for (final s in schedules) {
                  if (s.courseId == course.id) allSchedules.add(s);
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
