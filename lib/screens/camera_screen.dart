import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

  Map<String, String> _extractStudentInfo(String text) {
    final Map<String, String> studentInfo = {};
    
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    final namePatterns = [
      RegExp(r'(?:student\s*)?name\s*[:=]\s*(.+)', caseSensitive: false),
      RegExp(r'name\s*[:=]\s*(.+)', caseSensitive: false),
      RegExp(r'student\s*[:=]\s*(.+)', caseSensitive: false),
    ];
    
    final idPatterns = [
      RegExp(r'(?:student\s*)?(?:id|roll\s*no\.?|roll\s*number|reg\s*no\.?|registration\s*no\.?)\s*[:=]\s*([A-Za-z0-9\-\/]+)', caseSensitive: false),
      RegExp(r'(?:id|roll|reg)\s*[:=]\s*([A-Za-z0-9\-\/]+)', caseSensitive: false),
      RegExp(r'(\d{2,}[A-Za-z0-9\-\/]*)', caseSensitive: false),
    ];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && studentInfo['name'] == null) {
          final name = match.group(1)?.trim();
          if (name != null && name.length > 2 && !RegExp(r'^\d+$').hasMatch(name)) {
            studentInfo['name'] = name;
            break;
          }
        }
      }
      
      for (final pattern in idPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && studentInfo['id'] == null) {
          final id = match.group(1)?.trim();
          if (id != null && id.length >= 2) {
            studentInfo['id'] = id;
            break;
          }
        }
      }
      
      if (studentInfo['name'] != null && studentInfo['id'] != null) {
        break;
      }
    }
    
    return studentInfo;
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
      
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final InputImage inputImage = InputImage.fromFilePath(image.path);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String fullText = '';
      for (TextBlock block in recognizedText.blocks) {
        fullText += block.text + '\n';
      }
      
      final studentInfo = _extractStudentInfo(fullText);
      
      await textRecognizer.close();
      
      if (mounted) {
        _showStudentInfoDialog(studentInfo);
      }
    } catch (e) {
      print('Error during text recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
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

  void _showStudentInfoDialog(Map<String, String> studentInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Student Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentInfo['name'] != null) ...[
              _buildInfoRow('Name', studentInfo['name']!),
              const SizedBox(height: 12),
            ],
            if (studentInfo['id'] != null) ...[
              _buildInfoRow('ID/Roll No.', studentInfo['id']!),
              const SizedBox(height: 12),
            ],
            if (studentInfo.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No student information found.\nPlease ensure the name/ID is clearly visible.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Retry'),
          ),
          if (studentInfo.isNotEmpty) ...[
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, studentInfo);
              },
              child: const Text('Confirm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Student Info'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    'Extracting student information...',
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
            child: const Text(
              'Position the answer sheet so the student name/ID section is clearly visible',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
} 