import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/teacher_enrollment_service.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';

/// Teacher Enrollment Page - CSV/Excel/Manual Entry
class TeacherEnrollmentPage extends StatefulWidget {
  const TeacherEnrollmentPage({super.key});

  @override
  State<TeacherEnrollmentPage> createState() => _TeacherEnrollmentPageState();
}

class _TeacherEnrollmentPageState extends State<TeacherEnrollmentPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _isImportingData = false;
  Uint8List? _excelBytes;
  
  // Manual entry fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _subjectsController = TextEditingController();
  int _selectedTab = 0; // 0: CSV/Excel, 1: Manual Entry

  @override
  void dispose() {
    _csvController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      
      setState(() {
        if (file.extension == 'xlsx') {
          _excelBytes = bytes;
          _csvController.text = '[Excel File Selected: ${file.name}]';
        } else {
          _excelBytes = null;
          _csvController.text = utf8.decode(bytes);
        }
      });
    }
  }

  Future<void> _importData() async {
    final text = _csvController.text.trim();
    if (text.isEmpty && _excelBytes == null) {
      _showSnack('Please select a file or paste CSV data.');
      return;
    }

    setState(() => _isImportingData = true);
    _showSnack('Importing teacher data...');
    
    try {
      final enrollmentService = TeacherEnrollmentService();
      TeacherImportSummary summary;

      if (_excelBytes != null && text.startsWith('[Excel')) {
        summary = await enrollmentService.importFromExcelBytes(_excelBytes!);
      } else if (_excelBytes != null) {
        summary = await enrollmentService.importFromExcelBytes(_excelBytes!);
      } else {
        summary = await enrollmentService.importFromRawCsv(text);
      }

      if (summary.errorCount > 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Import Completed with ${summary.errorCount} error(s)'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successfully imported: ${summary.successCount} teachers',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (summary.errorCount > 0) ...[
                      const SizedBox(height: 16),
                      const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: summary.errors.length,
                          itemBuilder: (context, index) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            title: Text(
                              summary.errors[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        
        if (mounted) {
          _showSnack(
            'Imported: ${summary.successCount}/${summary.totalRows} teachers. '
            '${summary.errorCount} error(s) - see details in dialog.',
          );
        }
      } else {
        if (mounted) {
          _showSnack(
            'Successfully imported ${summary.successCount}/${summary.totalRows} teachers! '
            'Password for all teachers: 123456',
          );
        }
        // Clear input
        setState(() {
          _csvController.clear();
          _excelBytes = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Import error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnack('Import error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingData = false);
      }
    }
  }

  Future<void> _createTeacherManually() async {
    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final subjectsStr = _subjectsController.text.trim();

    if (name.isEmpty || department.isEmpty) {
      _showSnack('Please fill all required fields (Name, Department).');
      return;
    }

    setState(() => _isImportingData = true);
    _showSnack('Creating teacher...');

    try {
      final enrollmentService = TeacherEnrollmentService();
      
      // Parse subject codes from comma-separated string
      final subjectCodes = subjectsStr
          .split(',')
          .map((code) => code.trim())
          .where((code) => code.isNotEmpty)
          .toList();

      await enrollmentService.createTeacherManually(
        name: name,
        department: department,
        subjectCodes: subjectCodes,
      );

      if (mounted) {
        _showSnack('Teacher created successfully! Password: 123456');
        // Clear form
        setState(() {
          _nameController.clear();
          _departmentController.clear();
          _subjectsController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error creating teacher: $e');
      if (mounted) {
        _showSnack('Error creating teacher: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingData = false);
      }
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Teacher Enrollment'),
        backgroundColor: colors.backgroundSurface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: colors.backgroundSurface,
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'CSV/Excel Upload',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Manual Entry',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingTokens.space16),
              child: _selectedTab == 0 ? _buildCsvExcelTab() : _buildManualEntryTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsvExcelTab() {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Format sample
        Container(
          padding: const EdgeInsets.all(SpacingTokens.space16),
          decoration: BoxDecoration(
            color: colors.backgroundSurface,
            borderRadius: RadiusTokens.card,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(
                'Format sample:',
                role: TypographyRole.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: SpacingTokens.space8),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.space12),
                decoration: BoxDecoration(
                  color: colors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  'Name,Department,Subjects\n'
                  'Dr. John Smith,Computer Engineering,123456,123457\n'
                  'Prof. Jane Doe,Mechanical Engineering,123458,123459',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.space12),
              Text(
                '• Name: Full name of teacher (e.g., Dr. John Smith)\n'
                '• Department: Department name (e.g., Computer Engineering)\n'
                '• Subjects: Comma-separated subject codes (e.g., 123456,123457)\n'
                '• Password: All teachers will have password "123456"',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space24),
        
        // Input area
        TextField(
          controller: _csvController,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Paste CSV rows here or select a file (CSV/Excel)',
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.card,
            ),
            filled: true,
            fillColor: colors.backgroundSurface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space16),
        
        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isImportingData ? null : _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select File'),
              ),
            ),
            const SizedBox(width: SpacingTokens.space12),
            Expanded(
              flex: 2,
              child: DSButton(
                label: _isImportingData ? 'Importing...' : 'Import Data',
                onPressed: _isImportingData ? null : _importData,
                icon: Icons.check,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualEntryTab() {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.space16),
          decoration: BoxDecoration(
            color: colors.backgroundSurface,
            borderRadius: RadiusTokens.card,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(
                'Manual Entry',
                role: TypographyRole.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: SpacingTokens.space8),
              Text(
                'Fill in the details below to create a teacher manually. '
                'Subject codes will be converted to subject IDs automatically.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space24),
        
        // Name field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name *',
            hintText: 'e.g., Dr. John Smith',
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.card,
            ),
            filled: true,
            fillColor: colors.backgroundSurface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space16),
        
        // Department field
        TextField(
          controller: _departmentController,
          decoration: InputDecoration(
            labelText: 'Department *',
            hintText: 'e.g., Computer Engineering',
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.card,
            ),
            filled: true,
            fillColor: colors.backgroundSurface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space16),
        
        // Subjects field
        TextField(
          controller: _subjectsController,
          decoration: InputDecoration(
            labelText: 'Subjects (Optional)',
            hintText: 'Comma-separated codes: 123456,123457',
            helperText: 'Enter subject codes separated by commas',
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.card,
            ),
            filled: true,
            fillColor: colors.backgroundSurface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space24),
        
        // Password info
        Container(
          padding: const EdgeInsets.all(SpacingTokens.space12),
          decoration: BoxDecoration(
            color: colors.accentPrimary.withOpacity(0.1),
            borderRadius: RadiusTokens.card,
            border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colors.accentPrimary, size: 20),
              const SizedBox(width: SpacingTokens.space8),
              Expanded(
                child: Text(
                  'Password for all teachers: 123456',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space24),
        
        // Submit button
        DSButton(
          label: _isImportingData ? 'Creating...' : 'Create Teacher',
          onPressed: _isImportingData ? null : _createTeacherManually,
          icon: Icons.add,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.space16),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.backgroundSurface,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.textOnAccent : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

