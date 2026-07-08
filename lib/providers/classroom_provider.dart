import 'package:flutter/material.dart';
import '../models/classroom.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// 空教室查询状态管理
class ClassroomProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Classroom> _classrooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 筛选条件
  String? _selectedBuilding;
  int _selectedDayOfWeek = 1; // 周一
  int _selectedStartPeriod = 1; // 第1节
  int _selectedDuration = 2; // 持续2节

  // Getters
  List<Classroom> get classrooms => _classrooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedBuilding => _selectedBuilding;
  int get selectedDayOfWeek => _selectedDayOfWeek;
  int get selectedStartPeriod => _selectedStartPeriod;
  int get selectedDuration => _selectedDuration;

  /// 设置教学楼筛选
  void setBuilding(String? building) {
    _selectedBuilding = building;
    notifyListeners();
  }

  /// 设置星期筛选
  void setDayOfWeek(int day) {
    _selectedDayOfWeek = day;
    notifyListeners();
  }

  /// 设置节次筛选
  void setPeriod(int startPeriod, int duration) {
    _selectedStartPeriod = startPeriod;
    _selectedDuration = duration;
    notifyListeners();
  }

  /// 查询空教室
  Future<void> queryClassrooms(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 将教学楼名称映射为爬虫代码（如 "第一教学楼" → "F101"）
      String? buildingCode;
      if (_selectedBuilding != null) {
        buildingCode = AppConstants.buildingNameToCode[_selectedBuilding];
      }

      final result = await _apiService.getFreeClassrooms(
        token: token,
        building: buildingCode,
        dayOfWeek: _selectedDayOfWeek,
        startPeriod: _selectedStartPeriod,
        duration: _selectedDuration,
      );

      if (result['classrooms'] != null) {
        _classrooms = (result['classrooms'] as List)
            .map((c) => Classroom.fromJson(c))
            .toList();
      } else {
        _classrooms = [];
      }
    } catch (e) {
      _errorMessage = '查询失败: $e';
      _classrooms = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
