/// 学期数据模型
class Semester {
  final String id; // 如 "2025-2026-1"
  final String name; // 如 "2025-2026学年第一学期"
  final String startDate; // ISO格式: 2026-02-23
  final String endDate;
  final int totalWeeks;
  bool isCurrent;

  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.totalWeeks,
    this.isCurrent = false,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalWeeks: json['total_weeks'] is int ? json['total_weeks'] : int.tryParse(json['total_weeks']?.toString() ?? '20') ?? 20,
      isCurrent: json['is_current'] == true || json['is_current'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'total_weeks': totalWeeks,
        'is_current': isCurrent,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'total_weeks': totalWeeks,
        'is_current': isCurrent ? 1 : 0,
      };

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      startDate: map['start_date']?.toString() ?? '',
      endDate: map['end_date']?.toString() ?? '',
      totalWeeks: map['total_weeks'] is int ? map['total_weeks'] : 20,
      isCurrent: map['is_current'] == 1 || map['is_current'] == true,
    );
  }
}
