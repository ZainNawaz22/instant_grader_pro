import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:instant_grader_pro/models/answer_key.dart';
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';
import 'package:instant_grader_pro/omr_engine/omr_processor.dart';
import 'package:instant_grader_pro/services/grading_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isProcessing = false;
  
  final GradingService _gradingService = GradingService();
  AnswerKey? _selectedAnswerKey;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeGrading();
  }
  
  Future<void> _initializeGrading() async {
    await _gradingService.init();
    
    // Check if there are any answer keys available
    final answerKeys = _gradingService.getAllAnswerKeys();
    if (answerKeys.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No answer keys found. Please create one first.'),
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _extractStudentInfo(String imagePath) async {
    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String fullText = '';
      for (TextBlock block in recognizedText.blocks) {
        fullText += block.text + '\n';
      }
      
      await textRecognizer.close();
      
      // Extract roll number
      final rollNumberPattern = RegExp(r'(?:roll\s*no\.?|roll\s*number|id)\s*[:=]\s*([A-Za-z0-9\-\/]+)', caseSensitive: false);
      final rollMatch = rollNumberPattern.firstMatch(fullText);
      final rollNumber = rollMatch?.group(1)?.trim() ?? 'Unknown';
      
      // Extract name (optional)
      final namePattern = RegExp(r'(?:student\s*)?name\s*[:=]\s*(.+)', caseSensitive: false);
      final nameMatch = namePattern.firstMatch(fullText);
      final studentName = nameMatch?.group(1)?.trim();
      
      if (mounted) {
        _processAnswerSheet(imagePath, rollNumber, studentName);
      }
    } catch (e) {
      debugPrint('Error extracting student info: $e');
      if (mounted) {
        _processAnswerSheet(imagePath, 'Unknown', null);
      }
    }
  }
  
  Future<void> _processAnswerSheet(String imagePath, String rollNumber, String? studentName) async {
    try {
      // Process the answer sheet
      final List<OmrResult> omrResults = await OmrProcessor.processImage(imagePath);
      
      if (_selectedAnswerKey != null) {
        // Grade the student
        final result = await _gradingService.gradeStudent(
          rollNumber: rollNumber,
          studentName: studentName,
          answerKeyId: _selectedAnswerKey!.id,
          omrResults: omrResults,
        );
        
        if (mounted) {
          _showGradingResultDialog(result, _selectedAnswerKey!);
        }
      } else {
        if (mounted) {
          _showOmrResultDialog(omrResults.where((r) => r.isMarked).length);
        }
      }
    } catch (e) {
      debugPrint('Error processing answer sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing sheet: $e')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      // First extract student info, then process OMR
      await _extractStudentInfo(image.path);
      
    } catch (e) {
      debugPrint('Error during image capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  void _showGradingResultDialog(result, AnswerKey answerKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.assignment_turned_in,
              color: result.percentage >= 50 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Grading Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test: ${answerKey.testName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Roll Number: ${result.rollNumber}'),
              if (result.studentName != null) Text('Name: ${result.studentName}'),
              const Divider(),
              Text('Score: ${result.score.toStringAsFixed(1)} / ${result.maxScore.toStringAsFixed(1)}'),
              Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
              Text('Grade: ${result.grade}', style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: result.percentage >= 50 ? Colors.green : Colors.red,
              )),
              const SizedBox(height: 8),
              Text('Correct Answers: ${result.totalCorrect}'),
              Text('Incorrect Answers: ${result.totalIncorrect}'),
              Text('Unanswered: ${result.totalUnanswered}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('NEW SCAN'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showOmrResultDialog(int markCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Processing Complete'),
          ],
        ),
        content: Text('$markCount marks were detected on the sheet.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Potentially pop again to go back to the previous screen with results
              // Navigator.pop(context, ...);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showAnswerKeySelector() {
    final answerKeys = _gradingService.getAllAnswerKeys();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Answer Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (answerKeys.isEmpty)
              const Text('No answer keys available. Please create one first.')
            else
              ...answerKeys.map((key) => ListTile(
                title: Text(key.testName),
                subtitle: Text('${key.totalQuestions} questions • ${key.subject ?? "No subject"}'),
                trailing: _selectedAnswerKey?.id == key.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedAnswerKey = key;
                  });
                  Navigator.pop(context);
                },
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Answer Sheet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: _showAnswerKeySelector,
            tooltip: 'Select Answer Key',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isInitialized && !_isProcessing
          ? FloatingActionButton(
              onPressed: _captureImage,
              tooltip: 'Capture Image',
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Processing answer sheet...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Position the entire answer sheet inside the frame and hold steady',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (_selectedAnswerKey != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Answer Key: ${_selectedAnswerKey!.testName}',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
} 