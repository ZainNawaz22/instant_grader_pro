import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instant_grader_pro/omr_engine/omr_processor.dart';
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';
import 'dart:io';

class OmrTestScreen extends StatefulWidget {
  const OmrTestScreen({super.key});

  @override
  State<OmrTestScreen> createState() => _OmrTestScreenState();
}

class _OmrTestScreenState extends State<OmrTestScreen> {
  File? _selectedImage;
  List<OmrResult>? _results;
  bool _isProcessing = false;
  String _statusMessage = 'Select an image to test OMR processing';
  
  final ImagePicker _picker = ImagePicker();
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _results = null;
          _statusMessage = 'Image selected. Tap "Process" to analyze.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking image: $e';
      });
    }
  }
  
  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing image...';
    });
    
    try {
      final results = await OmrProcessor.processImage(_selectedImage!.path);
      
      setState(() {
        _results = results;
        _isProcessing = false;
        _statusMessage = 'Processing complete!';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error processing image: $e';
      });
    }
  }
  
  Widget _buildResultsGrid() {
    if (_results == null || _results!.isEmpty) {
      return const Center(
        child: Text('No results to display'),
      );
    }
    
    // Group results by question
    final Map<int, List<OmrResult>> groupedResults = {};
    for (final result in _results!) {
      final question = result.rowIndex + 1;
      groupedResults[question] ??= [];
      groupedResults[question]!.add(result);
    }
    
    return ListView.builder(
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final question = groupedResults.keys.elementAt(index);
        final options = groupedResults[question]!;
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question $question',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(options.length, (i) {
                    final option = options[i];
                    final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
                    
                    return Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: option.isMarked ? Colors.green : Colors.grey,
                              width: option.isMarked ? 3 : 1,
                            ),
                            color: option.isMarked 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: option.isMarked ? FontWeight.bold : FontWeight.normal,
                                color: option.isMarked ? Colors.green : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(option.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: option.isMarked ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMR Test Screen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera),
                      label: const Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _processImage,
                    child: _isProcessing
                        ? const CircularProgressIndicator()
                        : const Text('Process Image'),
                  ),
                ],
              ],
            ),
          ),
          if (_selectedImage != null)
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Expanded(
            child: _buildResultsGrid(),
          ),
        ],
      ),
    );
  }
} 