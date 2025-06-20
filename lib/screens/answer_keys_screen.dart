import 'package:flutter/material.dart';

class AnswerKeysScreen extends StatelessWidget {
  const AnswerKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Keys'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: const Center(
        child: Text(
          'Answer Keys Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
} 