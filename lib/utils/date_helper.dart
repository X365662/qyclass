import 'constants.dart';

/// 日期/周次计算工具
class DateHelper {
  /// 根据开学日期和当前日期计算当前是第几周（1-based）
  /// 返回 -1 表示未开学或假期
  static int getCurrentWeek(String semesterStartDate) {
    final start = DateTime.tryParse(semesterStartDate);
    if (start == null) return 1;

    final now = DateTime.now();
    final diff = now.difference(start).inDays;

    if (diff < 0) return -1; // 还没开学

    final week = (diff / 7).floor() + 1;

    // 确保在合理范围内
    if (week > AppConstants.totalWeeks) {
      return AppConstants.totalWeeks;
    }

    return week;
  }

  /// 获取指定周的周一日期
  static DateTime getMondayOfWeek(String semesterStartDate, int week) {
    final start = DateTime.tryParse(semesterStartDate);
    if (start == null) return DateTime.now();

    // 开学第一天通常是周一
    final monday = start.add(Duration(days: (week - 1) * 7));
    return monday;
  }

  /// 获取指定周的日期范围字符串（如 "3/17-3/23"）
  static String getWeekDateRange(String semesterStartDate, int week) {
    final monday = getMondayOfWeek(semesterStartDate, week);
    final sunday = monday.add(const Duration(days: 6));

    return '${monday.month}/${monday.day}-${sunday.month}/${sunday.day}';
  }

  /// 获取当前应该显示周次的默认值
  static int getDefaultWeek(String semesterStartDate) {
    final week = getCurrentWeek(semesterStartDate);
    if (week < 1) return 1;
    if (week > AppConstants.totalWeeks) return AppConstants.totalWeeks;
    return week;
  }

  /// 计算总共有多少周
  static int getTotalWeeks(String semesterStartDate, String semesterEndDate) {
    final start = DateTime.tryParse(semesterStartDate);
    final end = DateTime.tryParse(semesterEndDate);
    if (start == null || end == null) return AppConstants.totalWeeks;

    final diff = end.difference(start).inDays;
    return (diff / 7).ceil();
  }
}
