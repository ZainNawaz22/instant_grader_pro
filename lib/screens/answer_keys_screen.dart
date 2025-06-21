import 'package:flutter/material.dart';
import 'package:instant_grader_pro/models/answer_key.dart';
import 'package:instant_grader_pro/services/grading_service.dart';

class AnswerKeysScreen extends StatefulWidget {
  const AnswerKeysScreen({super.key});

  @override
  State<AnswerKeysScreen> createState() => _AnswerKeysScreenState();
}

class _AnswerKeysScreenState extends State<AnswerKeysScreen> {
  final GradingService _gradingService = GradingService();
  List<AnswerKey> _answerKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnswerKeys();
  }

  Future<void> _loadAnswerKeys() async {
    setState(() => _isLoading = true);
    try {
      await _gradingService.init();
      final keys = _gradingService.getAllAnswerKeys();
      setState(() {
        _answerKeys = keys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading answer keys: $e')),
        );
      }
    }
  }

  Future<void> _deleteAnswerKey(AnswerKey answerKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Answer Key'),
        content: Text('Are you sure you want to delete "${answerKey.testName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gradingService.deleteAnswerKey(answerKey.id);
        _loadAnswerKeys();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer key deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting answer key: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Keys'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _answerKeys.isEmpty
              ? _buildEmptyState()
              : _buildAnswerKeysList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateAnswerKey(),
        tooltip: 'Create Answer Key',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.key_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Answer Keys Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first answer key to start grading',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _navigateToCreateAnswerKey(),
                icon: const Icon(Icons.add),
                label: const Text('Create Answer Key'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _createDemoAnswerKey,
                icon: const Icon(Icons.science),
                label: const Text('Create Demo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoAnswerKey() async {
    try {
      final demoAnswerKey = AnswerKey(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testName: 'Sample Math Quiz',
        correctAnswers: ['A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B'],
        totalQuestions: 10,
        marksPerQuestion: 1.0,
        createdAt: DateTime.now(),
        subject: 'Mathematics',
        className: '10th Grade',
      );

      await _gradingService.saveAnswerKey(demoAnswerKey);
      _loadAnswerKeys();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo answer key created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating demo answer key: $e')),
        );
      }
    }
  }

  Widget _buildAnswerKeysList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _answerKeys.length,
      itemBuilder: (context, index) {
        final answerKey = _answerKeys[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                answerKey.totalQuestions.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              answerKey.testName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${answerKey.totalQuestions} questions'),
                if (answerKey.subject != null)
                  Text('Subject: ${answerKey.subject}'),
                if (answerKey.className != null)
                  Text('Class: ${answerKey.className}'),
                Text(
                  'Created: ${_formatDate(answerKey.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: const Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _viewAnswerKeyDetails(answerKey);
                    break;
                  case 'edit':
                    _navigateToEditAnswerKey(answerKey);
                    break;
                  case 'delete':
                    _deleteAnswerKey(answerKey);
                    break;
                }
              },
            ),
            onTap: () => _viewAnswerKeyDetails(answerKey),
          ),
        );
      },
    );
  }

  void _viewAnswerKeyDetails(AnswerKey answerKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(answerKey.testName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (answerKey.subject != null)
                Text('Subject: ${answerKey.subject}'),
              if (answerKey.className != null)
                Text('Class: ${answerKey.className}'),
              Text('Total Questions: ${answerKey.totalQuestions}'),
              Text('Marks per Question: ${answerKey.marksPerQuestion}'),
              Text('Total Marks: ${answerKey.maxScore}'),
              const SizedBox(height: 16),
              const Text(
                'Correct Answers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...answerKey.correctAnswers.asMap().entries.map((entry) {
                final questionNum = entry.key + 1;
                final answer = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Q$questionNum: $answer'),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditAnswerKey(answerKey);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateAnswerKey() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAnswerKeyScreen(),
      ),
    );
    if (result == true) {
      _loadAnswerKeys();
    }
  }

  Future<void> _navigateToEditAnswerKey(AnswerKey answerKey) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAnswerKeyScreen(answerKey: answerKey),
      ),
    );
    if (result == true) {
      _loadAnswerKeys();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CreateAnswerKeyScreen extends StatefulWidget {
  final AnswerKey? answerKey; // null for create, non-null for edit

  const CreateAnswerKeyScreen({super.key, this.answerKey});

  @override
  State<CreateAnswerKeyScreen> createState() => _CreateAnswerKeyScreenState();
}

class _CreateAnswerKeyScreenState extends State<CreateAnswerKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _marksPerQuestionController = TextEditingController(text: '1.0');
  
  int _numberOfQuestions = 5;
  List<String> _answers = List.filled(5, 'A');
  final List<String> _options = ['A', 'B', 'C', 'D', 'E'];
  
  bool _isLoading = false;
  final GradingService _gradingService = GradingService();

  @override
  void initState() {
    super.initState();
    _initializeGradingService();
    if (widget.answerKey != null) {
      _loadExistingAnswerKey();
    }
  }

  Future<void> _initializeGradingService() async {
    await _gradingService.init();
  }

  void _loadExistingAnswerKey() {
    final answerKey = widget.answerKey!;
    _testNameController.text = answerKey.testName;
    _subjectController.text = answerKey.subject ?? '';
    _classNameController.text = answerKey.className ?? '';
    _marksPerQuestionController.text = answerKey.marksPerQuestion.toString();
    _numberOfQuestions = answerKey.totalQuestions;
    _answers = List.from(answerKey.correctAnswers);
    
    // Ensure answers list has correct length
    while (_answers.length < _numberOfQuestions) {
      _answers.add('A');
    }
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _subjectController.dispose();
    _classNameController.dispose();
    _marksPerQuestionController.dispose();
    super.dispose();
  }

  void _updateNumberOfQuestions(int newCount) {
    setState(() {
      _numberOfQuestions = newCount;
      if (_answers.length < newCount) {
        // Add default answers for new questions
        while (_answers.length < newCount) {
          _answers.add('A');
        }
      } else if (_answers.length > newCount) {
        // Remove excess answers
        _answers = _answers.sublist(0, newCount);
      }
    });
  }

  Future<void> _saveAnswerKey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final answerKey = AnswerKey(
        id: widget.answerKey?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        testName: _testNameController.text.trim(),
        correctAnswers: _answers,
        totalQuestions: _numberOfQuestions,
        marksPerQuestion: double.parse(_marksPerQuestionController.text),
        createdAt: widget.answerKey?.createdAt ?? DateTime.now(),
        subject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
        className: _classNameController.text.trim().isEmpty ? null : _classNameController.text.trim(),
      );

      await _gradingService.saveAnswerKey(answerKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.answerKey == null 
              ? 'Answer key created successfully' 
              : 'Answer key updated successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving answer key: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.answerKey == null ? 'Create Answer Key' : 'Edit Answer Key'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveAnswerKey,
              icon: const Icon(Icons.save),
              tooltip: 'Save Answer Key',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _testNameController,
                      decoration: const InputDecoration(
                        labelText: 'Test Name *',
                        hintText: 'e.g., Math Quiz Chapter 5',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a test name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              hintText: 'e.g., Mathematics',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _classNameController,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              hintText: 'e.g., 10th Grade',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _marksPerQuestionController,
                            decoration: const InputDecoration(
                              labelText: 'Marks per Question',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter marks per question';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Please enter a valid positive number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _numberOfQuestions,
                            decoration: const InputDecoration(
                              labelText: 'Number of Questions',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(50, (index) => index + 1)
                                .map((num) => DropdownMenuItem(
                                      value: num,
                                      child: Text(num.toString()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateNumberOfQuestions(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Answer Key
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_numberOfQuestions, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Q${index + 1}:',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: _options.map((option) {
                                  return ButtonSegment<String>(
                                    value: option,
                                    label: Text(option),
                                  );
                                }).toList(),
                                selected: {_answers[index]},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _answers[index] = newSelection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveAnswerKey,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : Text(widget.answerKey == null ? 'Create Answer Key' : 'Update Answer Key'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 