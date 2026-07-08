import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/semester.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/color_helper.dart';

/// 课表数据状态管理
class ScheduleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();

  List<Course> _courses = [];
  List<CourseSchedule> _schedules = [];
  Map<String, String> _colorMap = {}; // courseName → hex color
  String? _token; // 爬虫登录 token
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Course> get courses => _courses;
  List<CourseSchedule> get schedules => _schedules;
  Map<String, String> get colorMap => _colorMap;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _schedules.isNotEmpty;

  /// 获取指定周的排课
  List<CourseSchedule> getSchedulesForWeek(int week) {
    return _schedules.where((s) => s.isActiveInWeek(week)).toList();
  }

  /// 获取指定课程的详情
  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  /// 获取课程颜色
  String getCourseColor(String courseName) {
    if (_colorMap.containsKey(courseName)) {
      return _colorMap[courseName]!;
    }
    final color = ColorHelper.assignColor(courseName);
    _colorMap[courseName] = color;
    return color;
  }

  /// 加载本地缓存的课表
  Future<void> loadCachedSchedule(String semesterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await _databaseService.getCoursesBySemester(semesterId);
      _schedules = await _databaseService.getSchedulesBySemester(semesterId);

      // 重建颜色映射
      _colorMap = {};
      for (final course in _courses) {
        if (course.color != null) {
          _colorMap[course.name] = course.color!;
        } else {
          _colorMap[course.name] = ColorHelper.assignColor(course.name);
        }
      }
    } catch (e) {
      _errorMessage = '加载缓存课表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 从教务系统导入课表
  Future<bool> importFromAcademicSystem({
    required String studentId,
    required String password,
    required String captchaId,
    required String captchaCode,
    required String semesterId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. 登录教务系统
      final loginResult = await _apiService.login(
        studentId: studentId,
        password: password,
        captchaId: captchaId,
        captchaCode: captchaCode,
      );

      if (loginResult['success'] != true) {
        _errorMessage = loginResult['message'] ?? '登录失败';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = loginResult['token'];

      // 2. 拉取课表
      final scheduleResult = await _apiService.getSchedule(_token!);

      // 3. 解析学期信息
      if (scheduleResult['semester'] != null) {
        final semester = Semester.fromJson(scheduleResult['semester']);
        await _databaseService.insertSemester(semester);
      }

      // 4. 存储课程
      if (scheduleResult['courses'] != null) {
        final courses = (scheduleResult['courses'] as List)
            .map((c) => Course.fromJson(c))
            .toList();
        await _databaseService.insertCourses(courses, semesterId);

        // 自动分配颜色
        for (final course in courses) {
          if (course.color == null) {
            final color = ColorHelper.assignColor(course.name);
            _colorMap[course.name] = color;
            await _databaseService.updateCourseColor(course.id, semesterId, color);
          } else {
            _colorMap[course.name] = course.color!;
          }
        }
      }

      // 5. 存储排课记录
      if (scheduleResult['schedules'] != null) {
        final schedules = (scheduleResult['schedules'] as List)
            .map((s) => CourseSchedule.fromJson(s))
            .toList();
        await _databaseService.insertSchedules(schedules, semesterId);
      }

      // 6. 重新加载数据
      await loadCachedSchedule(semesterId);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = '导入失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 刷新课表（重新从教务系统拉取）
  Future<bool> refreshSchedule(String semesterId) async {
    if (_token == null) {
      _errorMessage = '请先登录教务系统';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 清空旧数据
      await _databaseService.clearSemesterData(semesterId);

      // 重新拉取
      final scheduleResult = await _apiService.getSchedule(_token!);

      if (scheduleResult['courses'] != null) {
        final courses = (scheduleResult['courses'] as List)
            .map((c) => Course.fromJson(c))
            .toList();
        await _databaseService.insertCourses(courses, semesterId);
      }

      if (scheduleResult['schedules'] != null) {
        final schedules = (scheduleResult['schedules'] as List)
            .map((s) => CourseSchedule.fromJson(s))
            .toList();
        await _databaseService.insertSchedules(schedules, semesterId);
      }

      await loadCachedSchedule(semesterId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '刷新失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 手动添加课程及其排课记录
  Future<void> addCourseManually({
    required String semesterId,
    required String name,
    String? teacher,
    String location = '',
    int dayOfWeek = 1,
    int startPeriod = 1,
    int duration = 2,
    int startWeek = 1,
    int endWeek = 20,
    String weekType = 'every',
    double credit = 0,
    String type = '必修',
  }) async {
    // 生成唯一课程 ID
    final courseId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    final color = ColorHelper.assignColor(name);

    final course = Course(
      id: courseId,
      name: name,
      teacher: teacher,
      credit: credit,
      type: type,
      color: color,
    );

    final schedule = CourseSchedule(
      courseId: courseId,
      semesterId: semesterId,
      dayOfWeek: dayOfWeek,
      startPeriod: startPeriod,
      duration: duration,
      location: location,
      startWeek: startWeek,
      endWeek: endWeek,
      weekType: weekType,
    );

    // 插入数据库
    await _databaseService.insertSingleCourse(course, semesterId);
    await _databaseService.insertSingleSchedule(schedule, semesterId);

    // 更新内存列表
    _courses.add(course);
    _schedules.add(schedule);
    _colorMap[name] = color;
    notifyListeners();
  }

  /// 修改课程颜色
  Future<void> updateCourseColor(String courseId, String color, String semesterId) async {
    await _databaseService.updateCourseColor(courseId, semesterId, color);
    // 找到课程并更新
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx >= 0) {
      _courses[idx].color = color;
      _colorMap[_courses[idx].name] = color;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
