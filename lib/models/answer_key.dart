import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class AnswerKey extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String testName;
  
  @HiveField(2)
  final List<String> correctAnswers;
  
  @HiveField(3)
  final int totalQuestions;
  
  @HiveField(4)
  final double marksPerQuestion;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final String? subject;
  
  @HiveField(7)
  final String? className;

  AnswerKey({
    required this.id,
    required this.testName,
    required this.correctAnswers,
    required this.totalQuestions,
    this.marksPerQuestion = 1.0,
    required this.createdAt,
    this.subject,
    this.className,
  });

  double calculateScore(List<String?> studentAnswers) {
    double score = 0;
    for (int i = 0; i < correctAnswers.length && i < studentAnswers.length; i++) {
      if (studentAnswers[i] != null && correctAnswers[i] == studentAnswers[i]) {
        score += marksPerQuestion;
      }
    }
    return score;
  }

  double get maxScore => totalQuestions * marksPerQuestion;
  
  // Manual serialization methods
  Map<String, dynamic> toJson() => {
    'id': id,
    'testName': testName,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'marksPerQuestion': marksPerQuestion,
    'createdAt': createdAt.toIso8601String(),
    'subject': subject,
    'className': className,
  };
  
  factory AnswerKey.fromJson(Map<String, dynamic> json) => AnswerKey(
    id: json['id'],
    testName: json['testName'],
    correctAnswers: List<String>.from(json['correctAnswers']),
    totalQuestions: json['totalQuestions'],
    marksPerQuestion: json['marksPerQuestion']?.toDouble() ?? 1.0,
    createdAt: DateTime.parse(json['createdAt']),
    subject: json['subject'],
    className: json['className'],
  );
} 