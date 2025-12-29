import 'package:flutter/material.dart';

import 'design_system/theme/app_theme.dart';
import 'design_system/tokens/animation_tokens.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/auth_routes.dart';
import 'features/auth/role_selector_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/principal/principal_screen.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'features/teacher/attendance_confirm_screen.dart';
import 'features/student/student_screen.dart';
import 'features/face_recognition/face_recognition_demo_screen.dart';
import 'features/posts/posts_page.dart';

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      initialRoute: AuthRoutes.login,
      onGenerateRoute: (settings) {
        // Custom page transitions for auth screens
        if (settings.name == AuthRoutes.login ||
            settings.name == AuthRoutes.signup) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) {
              if (settings.name == AuthRoutes.login) {
                return const LoginScreen();
              } else {
                return const SignupScreen();
              }
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.1);
              const end = Offset.zero;
              const curve = AnimationCurves.screenEntry;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: AnimationTokens.durationScreenEntry,
          );
        }
        return null;
      },
      routes: {
        AuthRoutes.login: (context) => const LoginScreen(),
        AuthRoutes.signup: (context) => const SignupScreen(),
        '/role-selector': (context) => const RoleSelectorScreen(),
        '/admin': (context) => const AdminScreen(),
        '/principal': (context) => const PrincipalScreen(),
                '/teacher': (context) => const TeacherDashboardScreen(),
                '/teacher/attendance-confirm': (context) => const AttendanceConfirmScreen(),
                '/student': (context) => const StudentScreen(),
                '/face-recognition-demo': (context) => const FaceRecognitionDemoScreen(),
        '/posts': (context) => const PostsPage(),
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
    );
  }
}

