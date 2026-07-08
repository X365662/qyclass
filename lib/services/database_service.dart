import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/semester.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'qyclass.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        total_weeks INTEGER NOT NULL,
        is_current INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        teacher TEXT,
        credit REAL DEFAULT 0,
        type TEXT DEFAULT '必修',
        color TEXT,
        semester_id TEXT NOT NULL,
        PRIMARY KEY (id, semester_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE course_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL,
        semester_id TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_period INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        location TEXT NOT NULL,
        building TEXT,
        start_week INTEGER NOT NULL,
        end_week INTEGER NOT NULL,
        week_type TEXT DEFAULT 'every',
        FOREIGN KEY (course_id, semester_id) REFERENCES courses(id, semester_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE classrooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building TEXT NOT NULL,
        room_number TEXT NOT NULL,
        capacity INTEGER
      )
    ''');
  }

  // ==================== Semester ====================

  Future<void> insertSemester(Semester semester) async {
    final db = await database;
    await db.insert('semesters', semester.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Semester?> getCurrentSemester() async {
    final db = await database;
    final maps = await db.query('semesters',
        where: 'is_current = ?', whereArgs: [1], limit: 1);
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  Future<List<Semester>> getAllSemesters() async {
    final db = await database;
    final maps = await db.query('semesters', orderBy: 'start_date DESC');
    return maps.map((m) => Semester.fromMap(m)).toList();
  }

  // ==================== Course ====================

  Future<void> insertCourses(List<Course> courses, String semesterId) async {
    final db = await database;
    final batch = db.batch();
    for (final course in courses) {
      final map = course.toMap();
      map['semester_id'] = semesterId;
      batch.insert('courses', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Course>> getCoursesBySemester(String semesterId) async {
    final db = await database;
    final maps = await db.query('courses',
        where: 'semester_id = ?', whereArgs: [semesterId]);
    return maps.map((m) => Course.fromMap(m)).toList();
  }

  Future<Course?> getCourse(String courseId, String semesterId) async {
    final db = await database;
    final maps = await db.query('courses',
        where: 'id = ? AND semester_id = ?',
        whereArgs: [courseId, semesterId],
        limit: 1);
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  Future<void> updateCourseColor(String courseId, String semesterId, String color) async {
    final db = await database;
    await db.update(
      'courses',
      {'color': color},
      where: 'id = ? AND semester_id = ?',
      whereArgs: [courseId, semesterId],
    );
  }

  // ==================== CourseSchedule ====================

  Future<void> insertSchedules(List<CourseSchedule> schedules, String semesterId) async {
    final db = await database;
    final batch = db.batch();
    for (final schedule in schedules) {
      final map = schedule.toMap();
      map['semester_id'] = semesterId;
      map.remove('id'); // 让数据库自增
      batch.insert('course_schedule', map);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CourseSchedule>> getSchedulesBySemester(String semesterId) async {
    final db = await database;
    final maps = await db.query('course_schedule',
        where: 'semester_id = ?', whereArgs: [semesterId]);
    return maps.map((m) => CourseSchedule.fromMap(m)).toList();
  }

  /// 获取指定周次的排课列表
  Future<List<CourseSchedule>> getSchedulesForWeek(String semesterId, int week) async {
    final db = await database;
    final maps = await db.query('course_schedule',
        where: 'semester_id = ? AND start_week <= ? AND end_week >= ?',
        whereArgs: [semesterId, week, week]);
    return maps
        .map((m) => CourseSchedule.fromMap(m))
        .where((s) => s.isActiveInWeek(week))
        .toList();
  }

  // ==================== Clear & Re-import ====================

  /// 插入单条课程（手动添加用）
  Future<void> insertSingleCourse(Course course, String semesterId) async {
    final db = await database;
    final map = course.toMap();
    map['semester_id'] = semesterId;
    await db.insert('courses', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 插入单条排课记录（手动添加用）
  Future<int> insertSingleSchedule(CourseSchedule schedule, String semesterId) async {
    final db = await database;
    final map = schedule.toMap();
    map['semester_id'] = semesterId;
    map.remove('id'); // 让数据库自增
    return await db.insert('course_schedule', map);
  }

  /// 清空指定学期的所有数据（重新导入前调用）
  Future<void> clearSemesterData(String semesterId) async {
    final db = await database;
    await db.delete('course_schedule', where: 'semester_id = ?', whereArgs: [semesterId]);
    await db.delete('courses', where: 'semester_id = ?', whereArgs: [semesterId]);
    await db.delete('semesters', where: 'id = ?', whereArgs: [semesterId]);
  }

  /// 设置当前学期（取消其他学期的is_current标记）
  Future<void> setCurrentSemester(String semesterId) async {
    final db = await database;
    await db.update('semesters', {'is_current': 0});
    await db.update('semesters', {'is_current': 1},
        where: 'id = ?', whereArgs: [semesterId]);
  }
}
