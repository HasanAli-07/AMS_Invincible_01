import '../models/user_model.dart';

/// Role-based access control utilities
class RoleAccess {
  /// Check if role can perform action
  static bool canPerformAction(UserRole userRole, String action) {
    switch (action) {
      case 'upload_students':
      case 'manage_teachers':
      case 'manage_classes':
      case 'manage_subjects':
      case 'view_all_analytics':
      case 'generate_reports':
      case 'create_posts':
        return userRole == UserRole.admin || userRole == UserRole.principal;
      
      case 'mark_attendance':
      case 'view_own_subjects':
      case 'view_own_classes':
      case 'confirm_attendance':
        return userRole == UserRole.teacher || 
               userRole == UserRole.admin || 
               userRole == UserRole.principal;
      
      case 'view_own_attendance':
      case 'view_schedule':
      case 'view_posts':
        return true; // All roles can view their own data
      
      default:
        return false;
    }
  }

  /// Get accessible routes for role
  static List<String> getAccessibleRoutes(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.principal:
        return [
          '/principal',
          '/principal/upload-students',
          '/principal/manage-teachers',
          '/principal/academic-units',
          '/principal/subjects',
          '/principal/posts',
          '/principal/settings',
        ];
      case UserRole.teacher:
        return [
          '/teacher',
          '/teacher/subjects',
          '/teacher/attendance-confirm',
          '/teacher/attendance-history',
          '/teacher/notifications',
          '/teacher/profile',
        ];
      case UserRole.student:
        return [
          '/student',
        ];
    }
  }

  /// Check if user can access route
  static bool canAccessRoute(UserRole role, String route) {
    final accessibleRoutes = getAccessibleRoutes(role);
    return accessibleRoutes.contains(route);
  }
}

