import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// 手动添加课程页面
class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _locationController = TextEditingController();

  int _dayOfWeek = 1;
  int _startPeriod = 1;
  int _endPeriod = 2;
  int _startWeek = 1;
  int _endWeek = 20;
  String _weekType = 'every';
  double _credit = 0;
  String _courseType = '必修';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final scheduleProvider = context.read<ScheduleProvider>();
      final appProvider = context.read<AppProvider>();

      await scheduleProvider.addCourseManually(
        semesterId: appProvider.semesterId,
        name: _nameController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
        location: _locationController.text.trim(),
        dayOfWeek: _dayOfWeek,
        startPeriod: _startPeriod,
        duration: _endPeriod - _startPeriod + 1,
        startWeek: _startWeek,
        endWeek: _endWeek,
        weekType: _weekType,
        credit: _credit,
        type: _courseType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课程添加成功')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动添加课程'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 课程名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '课程名称 *',
                  hintText: '如：高等数学',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入课程名称' : null,
              ),
              const SizedBox(height: 16),

              // 教师
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  labelText: '教师（选填）',
                  hintText: '如：张老师',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // 上课地点
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '上课地点 *',
                  hintText: '如：A201',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入上课地点' : null,
              ),
              const SizedBox(height: 20),

              // 星期几
              _buildLabel('星期'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: List.generate(7, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(AppConstants.dayOfWeekNames[i]),
                  );
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _dayOfWeek = v);
                },
              ),
              const SizedBox(height: 16),

              // 节次范围
              _buildLabel('节次'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _startPeriod,
                      decoration: const InputDecoration(
                        labelText: '起始节',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text('第${i + 1}节'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _startPeriod = v;
                            if (_endPeriod < v) _endPeriod = v;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _endPeriod,
                      decoration: const InputDecoration(
                        labelText: '结束节',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(
                          12 - _startPeriod + 1,
                          (i) => DropdownMenuItem(
                                value: _startPeriod + i,
                                child: Text('第${_startPeriod + i}节'),
                              )),
                      onChanged: (v) {
                        if (v != null) setState(() => _endPeriod = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 周次范围
              _buildLabel('周次范围'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _startWeek,
                      decoration: const InputDecoration(
                        labelText: '起始周',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(20, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text('第${i + 1}周'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _startWeek = v;
                            if (_endWeek < v) _endWeek = v;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _endWeek,
                      decoration: const InputDecoration(
                        labelText: '结束周',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(
                          20 - _startWeek + 1,
                          (i) => DropdownMenuItem(
                                value: _startWeek + i,
                                child: Text('第${_startWeek + i}周'),
                              )),
                      onChanged: (v) {
                        if (v != null) setState(() => _endWeek = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 单双周
              _buildLabel('单双周'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _weekType,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'every', child: Text('每周')),
                  DropdownMenuItem(value: 'odd', child: Text('单周')),
                  DropdownMenuItem(value: 'even', child: Text('双周')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _weekType = v);
                },
              ),
              const SizedBox(height: 16),

              // 学分
              _buildLabel('学分'),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                value: _credit,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: List.generate(11, (i) {
                  final v = i * 0.5;
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v == 0 ? '无' : '$v 学分'),
                  );
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _credit = v);
                },
              ),
              const SizedBox(height: 16),

              // 课程类型
              _buildLabel('课程类型'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _courseType,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: '必修', child: Text('必修')),
                  DropdownMenuItem(value: '选修', child: Text('选修')),
                  DropdownMenuItem(value: '公选', child: Text('公选')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _courseType = v);
                },
              ),
              const SizedBox(height: 32),

              // 保存按钮
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存课程', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
