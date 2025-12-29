import 'package:flutter/material.dart';
import 'app.dart';
import 'core/state/app_state.dart';
import 'core/providers/app_provider.dart';
import 'core/data/data_initializer.dart';
import 'firebase/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (FREE tier)
  try {
    await initializeFirebase();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('App will continue with local storage only');
    // In production, you might want to handle this differently
  }
  
  // Initialize app state
  final appState = AppState();
  await appState.initialize();
  
  // Initialize default data
  await DataInitializer.initialize(
    studentRepo: appState.studentRepo,
    teacherRepo: appState.teacherRepo,
    subjectRepo: appState.subjectRepo,
    classRepo: appState.classRepo,
    scheduleRepo: appState.scheduleRepo,
    postRepo: appState.postRepo,
  );
  
  runApp(AppProvider(
    appState: appState,
    child: const AttendanceApp(),
  ));
}
