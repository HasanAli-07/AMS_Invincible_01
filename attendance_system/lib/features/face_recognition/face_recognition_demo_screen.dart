/// Face Recognition Demo Screen
/// 
/// This screen demonstrates how to use the face recognition system:
/// - Register faces (enrollment)
/// - Recognize faces (attendance marking)
/// - View statistics

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../ml/face_recognition_service.dart';
import '../../ml/face_detector_service.dart';
import '../../ml/face_embedding_service.dart';
import '../../ml/face_matcher.dart';
import '../../ml/face_repository.dart';
import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';

class FaceRecognitionDemoScreen extends StatefulWidget {
  const FaceRecognitionDemoScreen({super.key});

  @override
  State<FaceRecognitionDemoScreen> createState() => _FaceRecognitionDemoScreenState();
}

class _FaceRecognitionDemoScreenState extends State<FaceRecognitionDemoScreen> {
  late final FaceRecognitionService _faceRecognition;
  bool _isInitialized = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';
  Map<String, dynamic> _statistics = {};
  List<String> _recentResults = [];

  @override
  void initState() {
    super.initState();
    _initializeFaceRecognition();
  }

  Future<void> _initializeFaceRecognition() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Loading face recognition system...';
      });

      // Create services
      final faceDetector = FaceDetectorService();
      final embeddingService = FaceEmbeddingService();
      final faceMatcher = FaceMatcher(threshold: 0.70);
      final faceRepository = InMemoryFaceRepository();

      // Create main service
      _faceRecognition = FaceRecognitionService(
        faceDetector: faceDetector,
        embeddingService: embeddingService,
        faceMatcher: faceMatcher,
        faceRepository: faceRepository,
      );

      // Initialize (loads TFLite model)
      await _faceRecognition.initialize();

      // Load statistics
      _statistics = await _faceRecognition.getStatistics();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _statusMessage = 'Face recognition system ready!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Initialization failed: $e\n\nNote: Add TFLite model to assets/models/face_recognition.tflite for real recognition';
      });
    }
  }

  Future<void> _registerFace() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile == null) return;

      // Show dialog to enter user details
      final userId = await _showUserInputDialog('Enter User ID', 'e.g., student-123');
      if (userId == null || userId.isEmpty) return;

      final userName = await _showUserInputDialog('Enter User Name', 'e.g., John Doe');
      if (userName == null || userName.isEmpty) return;

      setState(() {
        _isLoading = true;
        _statusMessage = 'Registering face...';
      });

      final imageBytes = await pickedFile.readAsBytes();
      
      final storedFace = await _faceRecognition.registerFace(
        userId: userId,
        userName: userName,
        imageBytes: imageBytes,
        imagePath: pickedFile.path,
      );

      // Update statistics
      _statistics = await _faceRecognition.getStatistics();

      setState(() {
        _isLoading = false;
        _statusMessage = 'Face registered successfully!\n\nUser: $userName\nFace ID: ${storedFace.id}';
        _recentResults.insert(0, 'Registered: $userName (${storedFace.id})');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Registration failed: $e';
      });
    }
  }

  Future<void> _recognizeFaces() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = 'Recognizing faces...';
      });

      final imageBytes = await pickedFile.readAsBytes();
      
      final result = await _faceRecognition.recognizeFaces(
        imageBytes: imageBytes,
        imageWidth: 640,
        imageHeight: 480,
      );

      // Build result message
      final recognized = result.recognizedFaces
          .where((f) => f.isRecognized)
          .map((f) => '${f.recognizedUserName} (${(f.match!.similarity * 100).toStringAsFixed(1)}%)')
          .join(', ');

      final unknown = result.unknownCount;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Recognition Complete!\n\n'
            'Total Faces: ${result.totalFacesDetected}\n'
            'Recognized: ${result.recognizedCount}\n'
            'Unknown: $unknown\n\n'
            '${recognized.isNotEmpty ? "Recognized:\n$recognized" : "No faces recognized"}';
        
        if (recognized.isNotEmpty) {
          _recentResults.insert(0, 'Recognized: $recognized');
        } else if (unknown > 0) {
          _recentResults.insert(0, 'Unknown faces detected: $unknown');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Recognition failed: $e';
      });
    }
  }

  Future<String?> _showUserInputDialog(String title, String hint) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _faceRecognition.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Face Recognition Demo',
        department: 'Testing & Demo',
        onLogoutTap: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    'System Status',
                    role: TypographyRole.headline,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Insets.spaceVertical16,
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    DSText(
                      _statusMessage,
                      role: TypographyRole.body,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            Insets.spaceVertical24,

            // Statistics Card
            if (_isInitialized && _statistics.isNotEmpty)
              DSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      'Statistics',
                      role: TypographyRole.headline,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Insets.spaceVertical16,
                    _buildStatRow('Total Faces', '${_statistics['totalFaces'] ?? 0}'),
                    _buildStatRow('Total Users', '${_statistics['totalUsers'] ?? 0}'),
                    _buildStatRow('Threshold', '${_statistics['threshold'] ?? 0.70}'),
                    _buildStatRow(
                      'Model Status',
                      (_statistics['isModelLoaded'] ?? false) ? 'Loaded ✅' : 'Not Loaded ⚠️',
                    ),
                  ],
                ),
              ),
            if (_isInitialized && _statistics.isNotEmpty) Insets.spaceVertical24,

            // Action Buttons
            if (_isInitialized) ...[
              DSButton(
                label: 'Register Face (Enrollment)',
                onPressed: _isLoading ? null : _registerFace,
                icon: Icons.person_add,
              ),
              Insets.spaceVertical16,
              DSButton(
                label: 'Recognize Faces (Attendance)',
                onPressed: _isLoading ? null : _recognizeFaces,
                icon: Icons.face,
                variant: DSButtonVariant.secondary,
              ),
              Insets.spaceVertical24,
            ],

            // Recent Results
            if (_recentResults.isNotEmpty) ...[
              DSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      'Recent Results',
                      role: TypographyRole.headline,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Insets.spaceVertical16,
                    ..._recentResults.take(5).map(
                      (result) => Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.space8),
                        child: DSText(
                          result,
                          role: TypographyRole.body,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Instructions
            Insets.spaceVertical24,
            DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    'How to Use',
                    role: TypographyRole.headline,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Insets.spaceVertical16,
                  _buildInstruction(
                    '1. Register Face',
                    'Click "Register Face" and take a photo. Enter User ID and Name. Register 3-5 faces per person for best accuracy.',
                  ),
                  Insets.spaceVertical12,
                  _buildInstruction(
                    '2. Recognize Faces',
                    'Click "Recognize Faces" and take a photo. The system will detect and match all faces in the image.',
                  ),
                  Insets.spaceVertical12,
                  _buildInstruction(
                    '3. Check Results',
                    'View recognition results with similarity scores. Faces above 70% similarity are recognized.',
                  ),
                  Insets.spaceVertical12,
                  DSText(
                    'Note: Add TFLite model to assets/models/face_recognition.tflite for real recognition. Currently using fallback mode.',
                    role: TypographyRole.caption,
                    style: TextStyle(
                      color: colors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DSText(
            label,
            role: TypographyRole.body,
            style: TextStyle(color: colors.textSecondary),
          ),
          DSText(
            value,
            role: TypographyRole.body,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String title, String description) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          title,
          role: TypographyRole.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Insets.spaceVertical4,
        DSText(
          description,
          role: TypographyRole.body,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

