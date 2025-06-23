import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../utils/image_processing/corner_detector.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedFile;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _selectedFile = file;
    });

    await _processImage(file.path);
  }

  Future<void> _processImage(String imagePath) async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Could not decode image");
      }

      final result = await CornerDetector.detectCorners(image);

      debugPrint("Corner detection result: ${result.message}");
      
      if (mounted) {
        if (result.cornersDetected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'TIPS',
                textColor: Colors.white,
                onPressed: () => _showDetectionTips(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Process error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showDetectionTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corner Detection Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For better corner detection:'),
            SizedBox(height: 12),
            Text('• Use images with good lighting'),
            Text('• Ensure the document has clear edges'),
            Text('• Make sure the document fills most of the frame'),
            Text('• Avoid shadows and reflections'),
            Text('• Try images with higher resolution'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload and Process'),
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : _selectedFile == null
                ? const Text('Pick an image to start')
                : Image.file(File(_selectedFile!.path)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _pickImage,
        child: const Icon(Icons.upload),
      ),
    );
  }
} 