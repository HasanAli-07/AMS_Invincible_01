import 'package:flutter/material.dart';
import '../state/app_state.dart';

/// Provider for AppState - wraps ChangeNotifierProvider
class AppProvider extends InheritedWidget {
  final AppState appState;

  const AppProvider({
    super.key,
    required this.appState,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppProvider>();
    if (provider == null) {
      throw Exception('AppProvider not found in widget tree');
    }
    return provider.appState;
  }

  @override
  bool updateShouldNotify(AppProvider oldWidget) {
    return appState != oldWidget.appState;
  }
}

