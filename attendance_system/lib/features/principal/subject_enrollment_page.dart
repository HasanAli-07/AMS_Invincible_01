import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/subject_enrollment_service.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';

/// Subject Enrollment Page - CSV/Excel/Manual Entry
class SubjectEnrollmentPage extends StatefulWidget {
  const SubjectEnrollmentPage({super.key});

  @override
  State<SubjectEnrollmentPage> createState() => _SubjectEnrollmentPageState();
}

class _SubjectEnrollmentPageState extends State<SubjectEnrollmentPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _isImportingData = false;
  Uint8List? _excelBytes;
  
  // Manual entry fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  bool _isLab = false;
  int _selectedTab = 0; // 0: CSV/Excel, 1: Manual Entry

  @override
  void dispose() {
    _csvController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _departmentController.dispose();
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
    _showSnack('Importing subject data...');
    
    try {
      final enrollmentService = SubjectEnrollmentService();
      SubjectImportSummary summary;

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
                      'Successfully imported: ${summary.successCount} subjects',
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
            'Imported: ${summary.successCount}/${summary.totalRows} subjects. '
            '${summary.errorCount} error(s) - see details in dialog.',
          );
        }
      } else {
        if (mounted) {
          _showSnack(
            'Successfully imported ${summary.successCount}/${summary.totalRows} subjects!',
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

  Future<void> _createSubjectManually() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final department = _departmentController.text.trim();

    if (name.isEmpty || code.isEmpty || department.isEmpty) {
      _showSnack('Please fill all required fields (Name, Code, Department).');
      return;
    }

    setState(() => _isImportingData = true);
    _showSnack('Creating subject...');

    try {
      final enrollmentService = SubjectEnrollmentService();
      await enrollmentService.createSubjectManually(
        name: name,
        code: code,
        department: department,
        isLab: _isLab,
      );

      if (mounted) {
        _showSnack('Subject created successfully!');
        // Clear form
        setState(() {
          _nameController.clear();
          _codeController.clear();
          _departmentController.clear();
          _isLab = false;
        });
      }
    } catch (e) {
      debugPrint('Error creating subject: $e');
      if (mounted) {
        _showSnack('Error creating subject: $e');
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
        title: const Text('Subject Enrollment'),
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
                  'Name,Code,Department,IsLab\n'
                  'Data Structures,123456,Computer Engineering,0\n'
                  'Data Structures Lab,123457,Computer Engineering,1',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.space12),
              Text(
                '• Name: Subject name (e.g., Data Structures)\n'
                '• Code: Subject code (e.g., 123456)\n'
                '• Department: Department name (e.g., Computer Engineering)\n'
                '• IsLab: 0 for Theory, 1 for Lab',
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
                'Fill in the details below to create a subject manually.',
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
            hintText: 'e.g., Data Structures',
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.card,
            ),
            filled: true,
            fillColor: colors.backgroundSurface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space16),
        
        // Code field
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Code *',
            hintText: 'e.g., 123456',
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
        
        // IsLab toggle
        Container(
          padding: const EdgeInsets.all(SpacingTokens.space16),
          decoration: BoxDecoration(
            color: colors.backgroundSurface,
            borderRadius: RadiusTokens.card,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      'Subject Type',
                      role: TypographyRole.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: SpacingTokens.space4),
                    Text(
                      _isLab ? 'Laboratory Subject' : 'Theory Subject',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isLab,
                onChanged: (value) => setState(() => _isLab = value),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.space24),
        
        // Submit button
        DSButton(
          label: _isImportingData ? 'Creating...' : 'Create Subject',
          onPressed: _isImportingData ? null : _createSubjectManually,
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

