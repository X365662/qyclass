/// 课程数据模型
class Course {
  final String id;
  final String name;
  final String? teacher;
  final double credit;
  final String type; // 必修, 选修, 公选
  String? color; // 自定义颜色 hex

  Course({
    required this.id,
    required this.name,
    this.teacher,
    this.credit = 0,
    this.type = '必修',
    this.color,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      teacher: json['teacher']?.toString(),
      credit: (json['credit'] is int) ? (json['credit'] as int).toDouble() : (json['credit'] ?? 0).toDouble(),
      type: json['type']?.toString() ?? '必修',
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'credit': credit,
      'type': type,
      'color': color,
    };
  }

  /// 用于在 SQLite 中插入/更新
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'credit': credit,
      'type': type,
      'color': color,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      teacher: map['teacher']?.toString(),
      credit: (map['credit'] is int) ? (map['credit'] as int).toDouble() : (map['credit'] ?? 0).toDouble(),
      type: map['type']?.toString() ?? '必修',
      color: map['color']?.toString(),
    );
  }
}
