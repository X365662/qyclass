import 'package:flutter/material.dart';

/// 周次选择器 — 显示周次、日期范围、进度条，支持触控箭头和手势滑动
class WeekSelector extends StatelessWidget {
  final int currentWeek;
  final int totalWeeks;
  final String weekDateRange;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const WeekSelector({
    super.key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.weekDateRange,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFirst = currentWeek <= 1;
    final isLast = currentWeek >= totalWeeks;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 上一周
              _ArrowButton(
                icon: Icons.chevron_left,
                enabled: !isFirst,
                onTap: isFirst ? null : onPrevious,
              ),
              // 周次信息
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '第 $currentWeek 周',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekDateRange,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // 下一周
              _ArrowButton(
                icon: Icons.chevron_right,
                enabled: !isLast,
                onTap: isLast ? null : onNext,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 学期进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: currentWeek / totalWeeks,
              minHeight: 3,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _ArrowButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? cs.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: enabled ? cs.onSurface : cs.outlineVariant,
          size: 22,
        ),
      ),
    );
  }
}
