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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧彩色 accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            // 卡片主体
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(60),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textColor(color),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location != null && location!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location!,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withAlpha(180),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _textColor(Color bg) {
    // 根据亮度自适应文字颜色
    final luminance = (0.299 * bg.red + 0.587 * bg.green + 0.114 * bg.blue);
    return luminance > 140 ? bg.withAlpha(220) : bg;
  }
}
