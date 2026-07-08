import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../utils/constants.dart';

/// 课程详情 BottomSheet
class CourseDetailSheet extends StatelessWidget {
  final Course? course;
  final List<CourseSchedule> schedules; // 该课程的所有排课记录
  final Color color;

  const CourseDetailSheet({
    super.key,
    required this.course,
    required this.schedules,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (course == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽手柄
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 课程名 + 颜色标记
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 详细信息
          _buildInfoRow(Icons.person_outline, '教师', course!.teacher ?? '未知'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.stars_outlined, '学分', '${course!.credit}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.category_outlined, '类型', course!.type),
          const SizedBox(height: 20),

          // 上课时间地点
          const Text(
            '上课安排',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...schedules.map((s) => _buildScheduleItem(s)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(CourseSchedule schedule) {
    final dayName = AppConstants.dayOfWeekNames[schedule.dayOfWeek - 1];
    final periodText = '第${schedule.startPeriod}-${schedule.startPeriod + schedule.duration - 1}节';
    final weekText = schedule.weekType == 'every'
        ? '${schedule.startWeek}-${schedule.endWeek}周'
        : '${schedule.startWeek}-${schedule.endWeek}周(${schedule.weekType == "odd" ? "单" : "双"}周)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dayName $periodText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${schedule.location}  |  $weekText',
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
    );
  }
}
