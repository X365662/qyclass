import 'package:flutter/material.dart';

/// 周次选择器 — 纯展示组件（通过手势滑动切换周次）
class WeekSelector extends StatelessWidget {
  final int currentWeek;
  final int totalWeeks;
  final String weekDateRange;

  const WeekSelector({
    super.key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.weekDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 周次标题
          Text(
            '第 $currentWeek 周',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 日期范围
          Text(
            weekDateRange,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          // 滑动提示
          Text(
            '← 左右滑动切换周次 →',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
