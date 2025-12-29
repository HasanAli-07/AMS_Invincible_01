import 'package:flutter/material.dart';

class InstitutionOverview {
  final int totalStudents;
  final int totalTeachers;
  final int totalUnits;
  final double overallAttendancePercent;

  const InstitutionOverview({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalUnits,
    required this.overallAttendancePercent,
  });
}

class CoreAction {
  final String title;
  final String helperText;
  final IconData icon;
  final String routeName;

  const CoreAction({
    required this.title,
    required this.helperText,
    required this.icon,
    required this.routeName,
  });
}

class AttendanceInsight {
  final String title;
  final String description;
  final ChartData? chartData;
  final IconData icon;

  const AttendanceInsight({
    required this.title,
    required this.description,
    this.chartData,
    required this.icon,
  });
}

class ChartData {
  final List<double> values;
  final List<String> labels;
  final String unit;

  const ChartData({
    required this.values,
    required this.labels,
    required this.unit,
  });
}

class ReportDefinition {
  final String name;
  final String description;
  final IconData icon;

  const ReportDefinition({
    required this.name,
    required this.description,
    required this.icon,
  });
}

class AlertItem {
  final String title;
  final String description;
  final AlertSeverity severity;
  final IconData icon;

  const AlertItem({
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
  });
}

enum AlertSeverity {
  info,
  warning,
  danger,
}

/// Mock data that can later be replaced by API integration.
class PrincipalDashboardMockData {
  static const InstitutionOverview overview = InstitutionOverview(
    totalStudents: 1250,
    totalTeachers: 86,
    totalUnits: 42,
    overallAttendancePercent: 91.3,
  );

  static const List<CoreAction> coreActions = [
    CoreAction(
      title: 'Upload Students',
      helperText: 'CSV + Photos',
      icon: Icons.upload_file,
      routeName: '/principal/upload-students',
    ),
    CoreAction(
      title: 'Manage Teachers',
      helperText: 'Add/Update',
      icon: Icons.people_outline,
      routeName: '/principal/manage-teachers',
    ),
    CoreAction(
      title: 'Academic Units',
      helperText: 'Classes/Depts',
      icon: Icons.class_outlined,
      routeName: '/principal/academic-units',
    ),
    CoreAction(
      title: 'Subjects',
      helperText: 'Configure',
      icon: Icons.menu_book_outlined,
      routeName: '/principal/subjects',
    ),
    CoreAction(
      title: 'Posts',
      helperText: 'Create Post',
      icon: Icons.article_outlined,
      routeName: '/principal/posts',
    ),
    CoreAction(
      title: 'Settings',
      helperText: 'Preferences',
      icon: Icons.settings_outlined,
      routeName: '/principal/settings',
    ),
  ];

  static const List<AttendanceInsight> analyticsInsights = [
    AttendanceInsight(
      title: '7-Day Attendance Trend',
      description: 'Overall attendance remains stable',
      icon: Icons.trending_up,
      chartData: ChartData(
        values: [88.5, 90.2, 91.0, 89.8, 91.3, 92.1, 91.3],
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        unit: '%',
      ),
    ),
    AttendanceInsight(
      title: 'Class-wise Performance',
      description: '3 classes below 75% threshold',
      icon: Icons.bar_chart,
      chartData: ChartData(
        values: [92.5, 88.3, 74.2, 91.8, 76.1, 89.5, 93.2],
        labels: ['10A', '10B', '10C', '11A', '11B', '12A', '12B'],
        unit: '%',
      ),
    ),
    AttendanceInsight(
      title: 'Teacher Consistency',
      description: '85% teachers submit on time',
      icon: Icons.check_circle_outline,
      chartData: ChartData(
        values: [95, 88, 92, 85, 90, 87, 93],
        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6', 'Week 7'],
        unit: '%',
      ),
    ),
  ];

  static const List<ReportDefinition> reports = [
    ReportDefinition(
      name: 'Daily Report',
      description: 'Today\'s attendance snapshot',
      icon: Icons.today_outlined,
    ),
    ReportDefinition(
      name: 'Unit-wise Report',
      description: 'Compare classes & departments',
      icon: Icons.compare_arrows,
    ),
    ReportDefinition(
      name: 'Teacher Report',
      description: 'Track submission by teacher',
      icon: Icons.person_outline,
    ),
    ReportDefinition(
      name: 'Monthly Summary',
      description: 'Consolidated overview',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  static const List<AlertItem> alerts = [
    AlertItem(
      title: 'Attendance Pending',
      description: '4 teachers haven\'t submitted today',
      severity: AlertSeverity.warning,
      icon: Icons.warning_amber_rounded,
    ),
    AlertItem(
      title: 'Data Upload Ready',
      description: 'New student batch CSV ready',
      severity: AlertSeverity.info,
      icon: Icons.cloud_upload_outlined,
    ),
    AlertItem(
      title: 'System Status',
      description: 'Face recognition running normally',
      severity: AlertSeverity.info,
      icon: Icons.check_circle_outline,
    ),
  ];
}
