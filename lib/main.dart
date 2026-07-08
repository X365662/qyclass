import 'package:flutter/material.dart';
import 'app.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 加载用户保存的服务器地址
  await ApiService.loadBaseUrl();
  runApp(const QYClassApp());
}
