/// 排课记录数据模型（核心表）
class CourseSchedule {
  final int? id; // 本地自增ID
  final String courseId;
  final String semesterId;
  final int dayOfWeek; // 1=周一, 7=周日
  final int startPeriod; // 起始节次 (1-12)
  final int duration; // 持续节数
  final String location; // 教室名
  final String? building; // 教学楼
  final int startWeek; // 起始周
  final int endWeek; // 结束周
  final String weekType; // 'every', 'odd', 'even'

  CourseSchedule({
    this.id,
    required this.courseId,
    required this.semesterId,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.duration,
    required this.location,
    this.building,
    required this.startWeek,
    required this.endWeek,
    this.weekType = 'every',
  });

  /// 判断在指定周是否上课
  bool isActiveInWeek(int week) {
    if (week < startWeek || week > endWeek) return false;
    if (weekType == 'odd') return week % 2 == 1;
    if (weekType == 'even') return week % 2 == 0;
    return true;
  }

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      id: json['id'] is int ? json['id'] : null,
      courseId: json['course_id']?.toString() ?? '',
      semesterId: json['semester_id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] is int ? json['day_of_week'] : int.tryParse(json['day_of_week']?.toString() ?? '1') ?? 1,
      startPeriod: json['start_period'] is int ? json['start_period'] : int.tryParse(json['start_period']?.toString() ?? '1') ?? 1,
      duration: json['duration'] is int ? json['duration'] : int.tryParse(json['duration']?.toString() ?? '2') ?? 2,
      location: json['location']?.toString() ?? '',
      building: json['building']?.toString(),
      startWeek: json['start_week'] is int ? json['start_week'] : int.tryParse(json['start_week']?.toString() ?? '1') ?? 1,
      endWeek: json['end_week'] is int ? json['end_week'] : int.tryParse(json['end_week']?.toString() ?? '18') ?? 18,
      weekType: json['week_type']?.toString() ?? 'every',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'semester_id': semesterId,
      'day_of_week': dayOfWeek,
      'start_period': startPeriod,
      'duration': duration,
      'location': location,
      'building': building,
      'start_week': startWeek,
      'end_week': endWeek,
      'week_type': weekType,
    };
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'course_id': courseId,
      'semester_id': semesterId,
      'day_of_week': dayOfWeek,
      'start_period': startPeriod,
      'duration': duration,
      'location': location,
      'building': building,
      'start_week': startWeek,
      'end_week': endWeek,
      'week_type': weekType,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    return CourseSchedule(
      id: map['id'] is int ? map['id'] : null,
      courseId: map['course_id']?.toString() ?? '',
      semesterId: map['semester_id']?.toString() ?? '',
      dayOfWeek: map['day_of_week'] is int ? map['day_of_week'] : 1,
      startPeriod: map['start_period'] is int ? map['start_period'] : 1,
      duration: map['duration'] is int ? map['duration'] : 2,
      location: map['location']?.toString() ?? '',
      building: map['building']?.toString(),
      startWeek: map['start_week'] is int ? map['start_week'] : 1,
      endWeek: map['end_week'] is int ? map['end_week'] : 18,
      weekType: map['week_type']?.toString() ?? 'every',
    );
  }
}
