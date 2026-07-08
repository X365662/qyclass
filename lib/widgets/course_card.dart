import 'package:flutter/material.dart';

/// 课表网格中的单个课程卡片
class CourseCard extends StatelessWidget {
  final String courseName;
  final String? location;
  final Color color;
  final VoidCallback? onTap;
  final double height;

  const CourseCard({
    super.key,
    required this.courseName,
    this.location,
    required this.color,
    this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              courseName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _darkenColor(color),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (location != null && location!.isNotEmpty) ...[
              const Spacer(),
              Text(
                location!,
                style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 让颜色更深一点（用于文字）
  Color _darkenColor(Color color) {
    return Color.fromARGB(
      color.alpha,
      (color.red * 0.6).round().clamp(0, 255),
      (color.green * 0.6).round().clamp(0, 255),
      (color.blue * 0.6).round().clamp(0, 255),
    );
  }
}
