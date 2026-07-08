import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';

/// 全局应用状态
class AppProvider extends ChangeNotifier {
  String _semesterId = '2025-2026-2';
  String _semesterName = '2025-2026学年第二学期';
  String _semesterStartDate = AppConstants.semesterStartDate;
  int _currentWeek = 1;
  int _totalWeeks = AppConstants.totalWeeks;
  bool _isLoading = false;

  // Getters
  String get semesterId => _semesterId;
  String get semesterName => _semesterName;
  String get semesterStartDate => _semesterStartDate;
  int get currentWeek => _currentWeek;
  int get totalWeeks => _totalWeeks;
  bool get isLoading => _isLoading;

  /// 初始化：计算当前周
  void init() {
    _currentWeek = DateHelper.getDefaultWeek(_semesterStartDate);
    notifyListeners();
  }

  /// 设置学期信息
  void setSemester({
    required String id,
    required String name,
    required String startDate,
    required int totalWeeks,
  }) {
    _semesterId = id;
    _semesterName = name;
    _semesterStartDate = startDate;
    _totalWeeks = totalWeeks;
    _currentWeek = DateHelper.getDefaultWeek(startDate);
    notifyListeners();
  }

  /// 切换到指定周
  void setCurrentWeek(int week) {
    if (week >= 1 && week <= _totalWeeks) {
      _currentWeek = week;
      notifyListeners();
    }
  }

  /// 切换到上一周
  void previousWeek() {
    if (_currentWeek > 1) {
      _currentWeek--;
      notifyListeners();
    }
  }

  /// 切换到下一周
  void nextWeek() {
    if (_currentWeek < _totalWeeks) {
      _currentWeek++;
      notifyListeners();
    }
  }

  /// 获取当前周的日期范围字符串
  String get weekDateRange {
    return DateHelper.getWeekDateRange(_semesterStartDate, _currentWeek);
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
