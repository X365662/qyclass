/// 应用常量

class AppConstants {
  // 学期起止日期（需要根据实际校历调整）
  static const String semesterStartDate = '2026-02-23'; // 下学期开学日
  static const int totalWeeks = 20;

  // 节次时间表（根据学校实际作息时间）
  static const List<PeriodTime> periodTimes = [
    PeriodTime(period: 1, start: '08:00', end: '08:45'),
    PeriodTime(period: 2, start: '08:55', end: '09:40'),
    PeriodTime(period: 3, start: '10:00', end: '10:45'),
    PeriodTime(period: 4, start: '10:55', end: '11:40'),
    PeriodTime(period: 5, start: '14:00', end: '14:45'),
    PeriodTime(period: 6, start: '14:55', end: '15:40'),
    PeriodTime(period: 7, start: '16:00', end: '16:45'),
    PeriodTime(period: 8, start: '16:55', end: '17:40'),
    PeriodTime(period: 9, start: '19:00', end: '19:45'),
    PeriodTime(period: 10, start: '19:55', end: '20:40'),
    PeriodTime(period: 11, start: '20:50', end: '21:35'),
    PeriodTime(period: 12, start: '21:45', end: '22:30'),
  ];

  // 星期中文名
  static const List<String> dayOfWeekNames = [
    '周一', '周二', '周三', '周四', '周五', '周六', '周日',
  ];

  // 课程预设颜色（Material Design 柔和色调）
  static const List<String> presetColors = [
    'FF6B6B', // 珊瑚红
    '4ECDC4', // 青绿
    '45B7D1', // 天蓝
    '96CEB4', // 薄荷绿
    'FFEAA7', // 暖黄
    'DDA0DD', // 梅紫
    'FF8C69', // 橘橙
    '87CEEB', // 淡蓝
    'F08080', // 浅珊瑚
    '98D8C8', // 浅薄荷
  ];

  // 教学楼列表（与爬虫 BUILDING_MAP 保持一致）
  static const List<String> defaultBuildings = [
    '第一教学楼', '第二教学楼', '第三教学楼', '第四教学楼', '第五教学楼',
    '实验楼', '第六教学楼（新）', '第七教学楼',
  ];

  // 教学楼名称 → 代码映射（传给爬虫 API）
  static const Map<String, String> buildingNameToCode = {
    '第一教学楼': 'F101',
    '第二教学楼': 'F102',
    '第三教学楼': 'F103',
    '第四教学楼': 'F104',
    '第五教学楼': 'F105',
    '实验楼': 'F106',
    '第六教学楼（新）': 'F106(新)',
    '第七教学楼': 'F107',
  };
}

/// 节次时间
class PeriodTime {
  final int period;
  final String start;
  final String end;

  const PeriodTime({
    required this.period,
    required this.start,
    required this.end,
  });

  String get label => '$start-$end';
}
