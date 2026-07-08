import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/classroom_provider.dart';
import 'screens/main_screen.dart';
import 'utils/theme.dart';

class QYClassApp extends StatelessWidget {
  const QYClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ClassroomProvider()),
      ],
      child: MaterialApp(
        title: '轻院课表',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
