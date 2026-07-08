/// 教室数据模型
class Classroom {
  final String building; // 教学楼
  final String roomNumber; // 教室号
  final int? capacity; // 容量

  Classroom({
    required this.building,
    required this.roomNumber,
    this.capacity,
  });

  /// 完整名称，如 "A座201"
  String get fullName => '$building$roomNumber';

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      building: json['building']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'building': building,
        'room_number': roomNumber,
        'capacity': capacity,
      };
}
