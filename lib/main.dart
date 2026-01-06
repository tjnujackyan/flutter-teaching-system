import 'package:flutter/material.dart';
import 'pages/student_login_page.dart';
import 'pages/student_home_page.dart';
import 'pages/teacher_login_page.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智慧教学',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StudentLoginPage(),
        '/home': (context) => const StudentHomePage(),
        '/teacher-login': (context) => const TeacherLoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

