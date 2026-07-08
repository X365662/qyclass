import 'constants.dart';

/// 课程颜色自动分配工具
class ColorHelper {
  static int _colorIndex = 0;

  /// 为课程自动分配颜色
  static String assignColor(String courseName) {
    // 用课程名的 hashCode 确定颜色（同一课程始终同色）
    final index = courseName.hashCode.abs() % AppConstants.presetColors.length;
    return AppConstants.presetColors[index];
  }

  /// 获取下一个预设颜色（轮换）
  static String nextColor() {
    final color = AppConstants.presetColors[_colorIndex % AppConstants.presetColors.length];
    _colorIndex++;
    return color;
  }

  /// 重置颜色索引
  static void reset() {
    _colorIndex = 0;
  }

  /// 将 hex 颜色字符串转为 Flutter Color 需要的 int
  static int hexToInt(String hex) {
    // 移除 # 前缀
    hex = hex.replaceAll('#', '');
    // 如果是 6 位 hex，前面加 FF（不透明）
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return int.parse(hex, radix: 16);
  }

  /// 生成课程颜色 Map（key: courseName, value: hex color）
  static Map<String, String> generateColorMap(List<String> courseNames) {
    final map = <String, String>{};
    for (final name in courseNames) {
      map[name] = assignColor(name);
    }
    return map;
  }
}
