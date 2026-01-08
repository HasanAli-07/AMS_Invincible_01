import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import 'dart:io';
import '../../ml/attendance_face_recognition_service.dart';
import '../../firebase/services/firestore_student_service.dart';
import '../../firebase/services/firestore_attendance_service.dart';
import '../../ml/face_models.dart';

/// Enhanced Attendance Confirmation Screen with Firestore integration
class AttendanceConfirmScreen extends StatefulWidget {
  final AttendancePhotoResult? recognitionResult;
  final String? imagePath;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String classId;
  final String className;
  final String teacherId;
  final DateTime date;

  const AttendanceConfirmScreen({
    super.key,
    this.recognitionResult,
    this.imagePath,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.date,
  });

  @override
  State<AttendanceConfirmScreen> createState() => _AttendanceConfirmScreenState();
}

class _AttendanceConfirmScreenState extends State<AttendanceConfirmScreen> {
  final FirestoreStudentService _studentService = FirestoreStudentService();
  final FirestoreAttendanceService _attendanceService = FirestoreAttendanceService();

  List<Map<String, dynamic>> _allStudents = [];
  Map<String, bool> _attendanceStatus = {}; // studentId -> isPresent
  Map<String, double?> _recognitionConfidence = {}; // studentId -> confidence
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClassStudents();
  }

  String _normalizeId(String id) {
    String normalized = id.trim();
    if (normalized.endsWith('.0')) {
      normalized = normalized.substring(0, normalized.length - 2);
    }
    return normalized;
  }

  Future<void> _loadClassStudents() async {
    setState(() => _isLoading = true);
    try {
      // Get all students in the class
      _allStudents = await _studentService.getStudentsByClass(widget.classId);
      
      // Initialize all students as absent by default
      for (final student in _allStudents) {
        final studentId = student['id'] as String;
        _attendanceStatus[studentId] = false;
        _recognitionConfidence[studentId] = null;
      }

      // Mark recognized students as present
      if (widget.recognitionResult != null) {
        debugPrint('AttendanceConfirm: Matching ${widget.recognitionResult!.recognizedStudents.length} recognized students');
        
        for (final recognizedStudent in widget.recognitionResult!.recognizedStudents) {
          // Allow processing even if isRecognized is false, provided we have a best guess ID
          if (recognizedStudent.studentId != null) {
            final normalizedRecId = _normalizeId(recognizedStudent.studentId!);
            
            // Find student in class list with matching ID or rollNumber
            bool found = false;
            for (final student in _allStudents) {
              final studentId = student['id'] as String;
              final rollNumber = student['rollNumber'] as String? ?? '';
              
              if (_normalizeId(studentId) == normalizedRecId || 
                  _normalizeId(rollNumber) == normalizedRecId) {
                _attendanceStatus[studentId] = true;
                _recognitionConfidence[studentId] = recognizedStudent.confidence;
                found = true;
                debugPrint('✅ Matched recognized student: ${recognizedStudent.studentId} to student record: $studentId');
                break;
              }
            }
            
            if (!found) {
              debugPrint('⚠️ Recognized student ID ${recognizedStudent.studentId} not found in this class list');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAttendance(String studentId) {
    setState(() {
      _attendanceStatus[studentId] = !(_attendanceStatus[studentId] ?? false);
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      final presentIds = <String>[];
      final absentIds = <String>[];

      for (final student in _allStudents) {
        final studentId = student['id'] as String;
        if (_attendanceStatus[studentId] == true) {
          presentIds.add(studentId);
        } else {
          absentIds.add(studentId);
        }
      }

      // Save attendance to Firestore
      await _attendanceService.createAttendanceSession(
        date: widget.date,
        subjectId: widget.subjectId,
        classId: widget.classId,
        teacherId: widget.teacherId,
        presentStudentIds: presentIds,
        absentStudentIds: absentIds,
        confirmedByTeacher: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int get _totalStudents => _allStudents.length;
  int get _presentCount => _attendanceStatus.values.where((v) => v == true).length;
  int get _absentCount => _totalStudents - _presentCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedDate = widget.date;
    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Confirm Attendance',
        department: widget.className,
        notificationCount: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: Insets.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Detection Preview Card
                  if (widget.recognitionResult?.imageBytes != null)
                    DSCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(SpacingTokens.space12)),
                            child: Stack(
                              children: [
                                Image.memory(
                                  widget.recognitionResult!.imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                Positioned.fill(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // We need to decode the image to get dimensions for proper scaling
                                      return FutureBuilder<ui.Image>(
                                        future: decodeImageFromList(widget.recognitionResult!.imageBytes!),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) return const SizedBox.shrink();
                                          
                                          return CustomPaint(
                                            painter: FacePainter(
                                              recognizedStudents: widget.recognitionResult!.recognizedStudents,
                                              image: snapshot.data!,
                                              canvasSize: constraints.biggest,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(SpacingTokens.space12),
                            child: Row(
                              children: [
                                Icon(Icons.face, color: colors.accentPrimary, size: 20),
                                const SizedBox(width: SpacingTokens.space8),
                                DSText(
                                  'AI detected ${widget.recognitionResult!.totalFacesDetected} faces',
                                  role: TypographyRole.body,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Insets.spaceVertical24,
                  // Course Info Card
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.space24),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary,
                      borderRadius: RadiusTokens.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DSText(
                          '${widget.subjectCode}: ${widget.subjectName}',
                          role: TypographyRole.displayLarge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Insets.spaceVertical8,
                        DSText(
                          widget.className,
                          role: TypographyRole.body,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Insets.spaceVertical16,
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white70, size: 18),
                            const SizedBox(width: SpacingTokens.space8),
                            DSText(
                              timeStr,
                              role: TypographyRole.body,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: SpacingTokens.space16),
                            DSText(
                              dateStr,
                              role: TypographyRole.body,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Insets.spaceVertical24,
                  // Attendance Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'TOTAL',
                          value: '$_totalStudents',
                          borderColor: null,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.space12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'PRESENT',
                          value: '$_presentCount',
                          borderColor: colors.success,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.space12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'ABSENT',
                          value: '$_absentCount',
                          borderColor: colors.danger,
                        ),
                      ),
                    ],
                  ),
                  Insets.spaceVertical24,
                  // Student List Header
                  Row(
                    children: [
                      DSText(
                        'Student List',
                        role: TypographyRole.headline,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                      const SizedBox(width: SpacingTokens.space4),
                      DSText(
                        'Tap to toggle',
                        role: TypographyRole.caption,
                      ),
                    ],
                  ),
                  Insets.spaceVertical16,
                  // Student List
                  ..._allStudents.map((student) {
                    final studentId = student['id'] as String;
                    final name = student['name'] as String? ?? 'Unknown';
                    final rollNumber = student['rollNumber'] as String? ?? '';
                    final isPresent = _attendanceStatus[studentId] ?? false;
                    final confidence = _recognitionConfidence[studentId];
                    final needsVerify = confidence != null && confidence < 0.7;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: SpacingTokens.space12),
                      child: _StudentCard(
                        id: rollNumber.isEmpty ? studentId.substring(0, 3) : rollNumber,
                        name: name,
                        confidence: confidence,
                        isPresent: isPresent,
                        needsVerify: needsVerify,
                        onTap: () => _toggleAttendance(studentId),
                      ),
                    );
                  }),
                  Insets.spaceVertical24,
                  // Warning Message
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.space12),
                    decoration: BoxDecoration(
                      color: colors.warning.withOpacity(0.1),
                      borderRadius: RadiusTokens.button,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
                        const SizedBox(width: SpacingTokens.space8),
                        Expanded(
                          child: DSText(
                            'Review and confirm attendance before saving.',
                            role: TypographyRole.body,
                            style: TextStyle(color: colors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Insets.spaceVertical24,
                  // Action Buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 400;
                      return isSmall
                          ? Column(
                              children: [
                                DSButton(
                                  label: _isSaving ? 'SAVING...' : 'CONFIRM & SAVE',
                                  onPressed: _isSaving ? null : _saveAttendance,
                                  icon: Icons.check,
                                ),
                                Insets.spaceVertical12,
                                DSButton(
                                  label: 'Cancel',
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                                  variant: DSButtonVariant.danger,
                                  icon: Icons.close,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: DSButton(
                                    label: 'Cancel',
                                    onPressed: _isSaving
                                        ? null
                                        : () => Navigator.pop(context),
                                    variant: DSButtonVariant.danger,
                                    icon: Icons.close,
                                  ),
                                ),
                                const SizedBox(width: SpacingTokens.space12),
                                Expanded(
                                  flex: 2,
                                  child: DSButton(
                                    label: _isSaving ? 'SAVING...' : 'CONFIRM & SAVE',
                                    onPressed: _isSaving ? null : _saveAttendance,
                                    icon: Icons.check,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                  Insets.spaceVertical32,
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? borderColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DSText(
            label,
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Insets.spaceVertical8,
          DSText(
            value,
            role: TypographyRole.displayLarge,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String id;
  final String name;
  final double? confidence;
  final bool isPresent;
  final bool needsVerify;
  final VoidCallback onTap;

  const _StudentCard({
    required this.id,
    required this.name,
    this.confidence,
    required this.isPresent,
    required this.needsVerify,
    required this.onTap,
  });

  String _getConfidenceText() {
    if (confidence == null) return 'Manual Entry';
    if (confidence! >= 0.9) return 'High Confidence';
    if (confidence! >= 0.7) return 'Medium Confidence';
    return 'Low Confidence';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: RadiusTokens.card,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.space16),
        decoration: BoxDecoration(
          color: colors.backgroundSurface,
          borderRadius: RadiusTokens.card,
          border: needsVerify
              ? Border(left: BorderSide(color: colors.warning, width: 4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSText(
                  id,
                  role: TypographyRole.caption,
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    name,
                    role: TypographyRole.body,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                  ),
                  Insets.spaceVertical4,
                  Wrap(
                    spacing: SpacingTokens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.face,
                        size: 14,
                        color: needsVerify ? colors.warning : colors.accentPrimary,
                      ),
                      Flexible(
                        child: DSText(
                          _getConfidenceText(),
                          role: TypographyRole.caption,
                          style: TextStyle(
                            color: needsVerify ? colors.warning : colors.textSecondary,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.space12,
                vertical: SpacingTokens.space8,
              ),
              decoration: BoxDecoration(
                color: isPresent
                    ? colors.success.withOpacity(0.1)
                    : colors.danger.withOpacity(0.1),
                borderRadius: RadiusTokens.button,
                border: Border.all(
                  color: isPresent ? colors.success : colors.danger,
                  width: 1,
                ),
              ),
              child: DSText(
                isPresent ? 'Present' : 'Absent',
                role: TypographyRole.caption,
                style: TextStyle(
                  color: isPresent ? colors.success : colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<RecognizedStudent> recognizedStudents;
  final ui.Image image; // Decoded image
  final Size canvasSize;

  FacePainter({
    required this.recognizedStudents,
    required this.image,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image.width == 0 || image.height == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Calculate scaling for BoxFit.cover
    final double scaleX = size.width / image.width;
    final double scaleY = size.height / image.height;
    final double scale = math.max(scaleX, scaleY);

    // Calculate centering offsets
    final double offsetX = (size.width - (image.width * scale)) / 2;
    final double offsetY = (size.height - (image.height * scale)) / 2;

    for (final face in recognizedStudents) {
      if (face.faceBoundingBox == null) continue;

      paint.color = face.isRecognized ? Colors.green : Colors.red;
      
      final rect = face.faceBoundingBox!;
      
      // Transform rect coordinates
      final double left = rect.left * scale + offsetX;
      final double top = rect.top * scale + offsetY;
      final double right = rect.right * scale + offsetX;
      final double bottom = rect.bottom * scale + offsetY;

      canvas.drawRect(
        ui.Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
