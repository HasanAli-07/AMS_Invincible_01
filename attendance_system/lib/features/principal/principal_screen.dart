import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_bottom_nav.dart';
import '../../design_system/components/ds_icon.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/components/ds_chart.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../core/providers/app_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/services/analytics_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/post_model.dart';
import '../../core/services/student_enrollment_service.dart';
import '../auth/auth_routes.dart';
import 'principal_dashboard_data.dart';
import 'student_enrollment_page.dart';
import 'view_models/principal_view_model.dart';

/// Enhanced Principal Dashboard - Simplified card structure
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  int _currentIndex = 0;
  AppState? _appState;
  late final PrincipalViewModel _viewModel;
  late final AnalyticsService _analyticsService;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    final appState = AppProvider.of(context);
    _appState = appState;
    _viewModel = PrincipalViewModel(appState: appState);
    _analyticsService = appState.analyticsService;
    _viewModel.addListener(_onViewModelChanged);
    _didInit = true;
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = _appState ?? AppProvider.of(context);
    final currentUser = appState.currentUser;
    final overviewData = _viewModel.getInstitutionOverview();
    final actions = PrincipalDashboardMockData.coreActions;
    final reports = PrincipalDashboardMockData.reports;

    // Create overview from real data
    final overview = InstitutionOverview(
      totalStudents: overviewData['totalStudents'] as int,
      totalTeachers: overviewData['totalTeachers'] as int,
      totalUnits: overviewData['totalClasses'] as int,
      overallAttendancePercent: (overviewData['overallAttendance'] as double),
    );

    Widget content;
    switch (_currentIndex) {
      case 1:
        content = _AnalyticsSection(
          analyticsService: _analyticsService,
          viewModel: _viewModel,
        );
        break;
      case 2:
        content = _ReportsSection(
          reports: reports,
          viewModel: _viewModel,
        );
        break;
      case 3:
        content = _PostsSection(viewModel: _viewModel);
        break;
      default:
        content = _HomeView(
          overview: overview,
          actions: actions,
          viewModel: _viewModel,
        );
    }

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: DSAppBar(
        name: currentUser?.name ?? 'Principal',
        department: currentUser?.department ?? 'Principal',
        notificationCount: 3,
        onLogoutTap: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AuthRoutes.login,
            (route) => false,
          );
        },
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: content,
      ),
      bottomNavigationBar: DSBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          // For the Posts tab, open the dedicated Posts page
          // instead of the older inline section.
          if (index == 3) {
            Navigator.of(context).pushNamed('/posts');
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          DSBottomNavItem(icon: Icons.dashboard_outlined, label: 'Home'),
          DSBottomNavItem(icon: Icons.insights_outlined, label: 'Analytics'),
          DSBottomNavItem(icon: Icons.file_present_outlined, label: 'Reports'),
          DSBottomNavItem(icon: Icons.article_outlined, label: 'Posts'),
        ],
      ),
    );
  }
}

/// Home View - Simplified layout
class _HomeView extends StatelessWidget {
  final InstitutionOverview overview;
  final List<CoreAction> actions;
  final PrincipalViewModel viewModel;

  const _HomeView({
    required this.overview,
    required this.actions,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InstitutionOverviewCard(overview: overview),
        Insets.spaceVertical24,
        _QuickActionsGrid(actions: actions, viewModel: viewModel),
        Insets.spaceVertical24,
        _AlertsSection(viewModel: viewModel),
      ],
    );
  }
}

/// Institution Overview - Single Card
class _InstitutionOverviewCard extends StatelessWidget {
  final InstitutionOverview overview;

  const _InstitutionOverviewCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space20),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: colors.accentPrimary, size: 24),
              const SizedBox(width: SpacingTokens.space12),
              DSText(
                'Institution Overview',
                role: TypographyRole.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Insets.spaceVertical24,
          // Stats Grid - 2x2 Layout
          Row(
            children: [
              Expanded(
                child: _OverviewStatItem(
                  icon: Icons.people_outlined,
                  label: 'Students',
                  value: '${overview.totalStudents}',
                  color: colors.accentPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.space16),
                color: colors.borderSubtle,
              ),
              Expanded(
                child: _OverviewStatItem(
                  icon: Icons.person_outline,
                  label: 'Teachers',
                  value: '${overview.totalTeachers}',
                  color: colors.accentSecondary,
                ),
              ),
            ],
          ),
          Insets.spaceVertical16,
          Container(height: 1, color: colors.borderSubtle),
          Insets.spaceVertical16,
          Row(
            children: [
              Expanded(
                child: _OverviewStatItem(
                  icon: Icons.class_outlined,
                  label: 'Units',
                  value: '${overview.totalUnits}',
                  color: colors.success,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.space16),
                color: colors.borderSubtle,
              ),
              Expanded(
                child: _OverviewStatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Attendance',
                  value: '${overview.overallAttendancePercent.toStringAsFixed(1)}%',
                  color: colors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: SpacingTokens.space8),
            Flexible(
              child: DSText(
                value,
                role: TypographyRole.displayLarge,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Insets.spaceVertical8,
        DSText(
          label,
          role: TypographyRole.caption,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Quick Actions - 2x2 Grid Layout (No cards, just containers)
class _QuickActionsGrid extends StatelessWidget {
  final List<CoreAction> actions;
  final PrincipalViewModel viewModel;

  const _QuickActionsGrid({
    required this.actions,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_outlined, color: context.colors.accentPrimary, size: 24),
            const SizedBox(width: SpacingTokens.space8),
            DSText(
              'Quick Actions',
              role: TypographyRole.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Insets.spaceVertical16,
        // 2x2 Grid Layout
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _QuickActionItem(action: actions[0], viewModel: viewModel)),
                const SizedBox(width: SpacingTokens.space12),
                Expanded(child: _QuickActionItem(action: actions[1], viewModel: viewModel)),
              ],
            ),
            const SizedBox(height: SpacingTokens.space12),
            Row(
              children: [
                Expanded(child: _QuickActionItem(action: actions[2], viewModel: viewModel)),
                const SizedBox(width: SpacingTokens.space12),
                Expanded(child: _QuickActionItem(action: actions[3], viewModel: viewModel)),
              ],
            ),
            if (actions.length > 4) ...[
              const SizedBox(height: SpacingTokens.space12),
              Row(
                children: [
                  Expanded(child: _QuickActionItem(action: actions[4], viewModel: viewModel)),
                  const SizedBox(width: SpacingTokens.space12),
                  Expanded(child: _QuickActionItem(action: actions[5], viewModel: viewModel)),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final CoreAction action;
  final PrincipalViewModel? viewModel;

  const _QuickActionItem({
    required this.action,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.backgroundSurface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleAction(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: colors.accentPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.helperText,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context) {
    switch (action.routeName) {
      case '/principal/upload-students':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const StudentEnrollmentPage(),
          ),
        );
        break;
      case '/principal/manage-teachers':
        _showManageTeachers(context);
        break;
      case '/principal/academic-units':
        _showManageClasses(context);
        break;
      case '/principal/subjects':
        _showManageSubjects(context);
        break;
      case '/principal/posts':
        Navigator.of(context).pushNamed('/posts');
        break;
      case '/principal/settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings - Coming soon')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.title} - Coming soon')),
        );
    }
  }

  void _showUploadDialog(BuildContext context) {
    final csvController = TextEditingController();
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Enrollment'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: CSV
                Card(
                  margin: EdgeInsets.zero,
                  color: colors.backgroundSurface,
                  shadowColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 1 — Upload Student CSV',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Required headers: student_id, name, roll_no, academic_unit',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _FormatPill(
                          title: 'CSV sample (copy/paste):',
                          content:
                              'student_id,name,roll_no,academic_unit\n'
                              's001,Jane Doe,10A001,CS-2024\n'
                              's002,John Smith,10A002,CS-2024',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: csvController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Paste CSV rows here for quick testing',
                            border: const OutlineInputBorder(),
                            hintStyle: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['csv'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              final bytes = file.bytes ??
                                  await File(file.path!).readAsBytes();
                              csvController.text = utf8.decode(bytes);
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select CSV file'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Step 2: ZIP
                Card(
                  margin: EdgeInsets.zero,
                  color: colors.backgroundSurface,
                  shadowColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 2 — Bulk Face Enrollment (ZIP)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ZIP structure: student_id/img1.jpg, img2.jpg, ...',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _FormatPill(
                          title: 'ZIP folder example:',
                          content:
                              'root/\n'
                              '├─ s001/\n'
                              '│   ├─ img1.jpg\n'
                              '│   └─ img2.jpg\n'
                              '├─ s002/\n'
                              '    ├─ face1.jpg\n'
                              '    └─ face2.jpg',
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            final zipResult = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['zip'],
                            );
                            if (zipResult == null || zipResult.files.isEmpty) return;

                            final file = zipResult.files.first;
                            final bytes =
                                file.bytes ?? await File(file.path!).readAsBytes();

                            final enrollmentService = StudentImageEnrollmentService();

                            Navigator.of(context).pop(); // close dialog while processing

                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Processing enrollment ZIP...'),
                              ),
                            );

                            try {
                              final summary =
                                  await enrollmentService.enrollFromZipBytes(bytes);

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Enrollment complete: '
                                    '${summary.embeddingsCreated}/${summary.totalImages} images → embeddings. '
                                    'No face: ${summary.imagesNoFace}, '
                                    'Multi-face: ${summary.imagesMultipleFaces}, '
                                    'Missing students: ${summary.missingStudents}.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Enrollment error: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.folder_zip),
                          label: const Text('Select ZIP for face enrollment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final csvText = csvController.text.trim();
              if (csvText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please paste CSV data first')),
                );
                return;
              }

              final enrollmentService = StudentCsvEnrollmentService();

              Navigator.of(context).pop(); // close dialog while processing

              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Importing students from CSV...'),
                ),
              );

              try {
                final summary =
                    await enrollmentService.importFromRawCsv(csvText);

                final msg = StringBuffer()
                  ..write(
                      'CSV import: ${summary.successCount}/${summary.totalRows} students created/updated.')
                  ..write(
                      summary.errorCount > 0 ? ' Errors: ${summary.errorCount}.' : '');

                messenger.showSnackBar(
                  SnackBar(content: Text(msg.toString())),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('CSV import error: $e')),
                );
              }
            },
            child: const Text('Import CSV'),
          ),
        ],
      ),
    );
  }

  void _showManageTeachers(BuildContext context) {
    if (viewModel == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Teachers'),
        content: Text('Total Teachers: ${viewModel!.teachers.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManageClasses(BuildContext context) {
    if (viewModel == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Academic Units'),
        content: Text('Total Classes: ${viewModel!.classes.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManageSubjects(BuildContext context) {
    if (viewModel == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subjects'),
        content: Text('Total Subjects: ${viewModel!.subjects.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (viewModel != null && titleController.text.isNotEmpty) {
                final appState = AppProvider.of(context);
                final post = Post(
                  id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  content: contentController.text,
                  authorId: appState.currentUser?.id ?? 'principal-1',
                  authorRole: appState.currentUser?.role ?? UserRole.principal,
                  createdAt: DateTime.now(),
                  targetRoles: ['student', 'teacher'],
                );
                viewModel!.createPost(post).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created successfully!')),
                  );
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _FormatPill extends StatelessWidget {
  final String title;
  final String content;

  const _FormatPill({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Analytics Section - Simplified
class _AnalyticsSection extends StatefulWidget {
  final AnalyticsService analyticsService;
  final PrincipalViewModel viewModel;

  const _AnalyticsSection({
    required this.analyticsService,
    required this.viewModel,
  });

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  List<double>? _weeklyTrend;
  Map<String, double>? _classPerformance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final trend = await widget.analyticsService.getWeeklyTrend(null);
      final performance = await widget.analyticsService.getClassWisePerformance();
      setState(() {
        _weeklyTrend = trend;
        _classPerformance = performance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.insights_outlined, color: context.colors.accentPrimary, size: 24),
            const SizedBox(width: SpacingTokens.space8),
            DSText(
              'Analytics & Insights',
              role: TypographyRole.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Insets.spaceVertical16,
        if (_weeklyTrend != null) _buildTrendCard(),
        if (_classPerformance != null) _buildClassPerformanceCard(),
      ],
    );
  }

  Widget _buildTrendCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.space16),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.space20),
        decoration: BoxDecoration(
          color: context.colors.backgroundSurface,
          borderRadius: RadiusTokens.card,
          border: Border.all(color: context.colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DSText(
              '7-Day Attendance Trend',
              role: TypographyRole.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Insets.spaceVertical16,
            DSLineChart(
              values: _weeklyTrend!,
              labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              unit: '%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassPerformanceCard() {
    final values = _classPerformance!.values.toList();
    final labels = _classPerformance!.keys.toList();
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space20),
      decoration: BoxDecoration(
        color: context.colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText(
            'Class-wise Performance',
            role: TypographyRole.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Insets.spaceVertical16,
          DSBarChart(
            values: values,
            labels: labels,
            unit: '%',
          ),
        ],
      ),
    );
  }
}

/// Reports Section - Simplified
class _ReportsSection extends StatelessWidget {
  final List<ReportDefinition> reports;
  final PrincipalViewModel viewModel;

  const _ReportsSection({
    required this.reports,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.file_present_outlined, color: colors.accentPrimary, size: 24),
            const SizedBox(width: SpacingTokens.space8),
            DSText(
              'Reports & Exports',
              role: TypographyRole.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Insets.spaceVertical16,
        ...reports.map(
          (report) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.space12),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Generating ${report.name}...')),
                );
              },
              borderRadius: RadiusTokens.card,
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.space16),
                decoration: BoxDecoration(
                  color: colors.backgroundSurface,
                  borderRadius: RadiusTokens.card,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      report.icon,
                      color: colors.accentSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: SpacingTokens.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DSText(
                            report.name,
                            role: TypographyRole.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Insets.spaceVertical4,
                          DSText(
                            report.description,
                            role: TypographyRole.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Posts Section - Simplified
class _PostsSection extends StatelessWidget {
  final PrincipalViewModel viewModel;

  _PostsSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final posts = viewModel.posts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, color: colors.accentPrimary, size: 24),
            const SizedBox(width: SpacingTokens.space8),
            DSText(
              'Posts & Announcements',
              role: TypographyRole.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            DSButton(
              label: 'Create',
              onPressed: () => _showCreatePost(context),
              icon: Icons.add,
              isSmall: true,
              fullWidth: false,
            ),
          ],
        ),
        Insets.spaceVertical16,
        if (posts.isEmpty)
          DSText(
            'No posts yet. Create your first post!',
            role: TypographyRole.body,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          )
        else
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.space12),
              child: _PostItem(
                title: post.title,
                content: post.content,
                date: _formatDate(post.createdAt),
                category: post.authorRole.toString().split('.').last.toUpperCase(),
                author: post.authorId,
                onDelete: () => viewModel.deletePost(post.id),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreatePost(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final appState = AppProvider.of(context);
                final post = Post(
                  id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  content: contentController.text,
                  authorId: appState.currentUser?.id ?? 'principal-1',
                  authorRole: appState.currentUser?.role ?? UserRole.principal,
                  createdAt: DateTime.now(),
                  targetRoles: ['student', 'teacher'],
                );
                viewModel.createPost(post).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created successfully!')),
                  );
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PostItem extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final String category;
  final String author;
  final VoidCallback? onDelete;

  const _PostItem({
    required this.title,
    required this.content,
    required this.date,
    required this.category,
    required this.author,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  title,
                  role: TypographyRole.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DSBadge(
                label: category,
                variant: DSBadgeVariant.secondary,
              ),
            ],
          ),
          Insets.spaceVertical8,
          DSText(
            content,
            role: TypographyRole.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Insets.spaceVertical12,
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: colors.textSecondary),
              const SizedBox(width: SpacingTokens.space4),
              DSText(
                author,
                role: TypographyRole.caption,
              ),
              const SizedBox(width: SpacingTokens.space16),
              Icon(Icons.calendar_today, size: 14, color: colors.textSecondary),
              const SizedBox(width: SpacingTokens.space4),
              DSText(
                date,
                role: TypographyRole.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Alerts Section - Simplified
class _AlertsSection extends StatelessWidget {
  final PrincipalViewModel viewModel;

  const _AlertsSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color _colorFor(AlertSeverity severity) {
      switch (severity) {
        case AlertSeverity.info:
          return colors.accentPrimary;
        case AlertSeverity.warning:
          return colors.warning;
        case AlertSeverity.danger:
          return colors.danger;
      }
    }

    // Show alerts based on data state
    final hasPendingTeachers = viewModel.teachers.length < 5; // Example alert
    if (!hasPendingTeachers) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_outlined, color: colors.accentPrimary, size: 24),
            const SizedBox(width: SpacingTokens.space8),
            DSText(
              'Alerts & Notifications',
              role: TypographyRole.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Insets.spaceVertical16,
        Container(
          padding: const EdgeInsets.all(SpacingTokens.space16),
          decoration: BoxDecoration(
            color: colors.backgroundSurface,
            borderRadius: RadiusTokens.card,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colors.accentPrimary),
              const SizedBox(width: SpacingTokens.space12),
              Expanded(
                child: DSText(
                  'System running normally. ${viewModel.teachers.length} teachers registered.',
                  role: TypographyRole.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
