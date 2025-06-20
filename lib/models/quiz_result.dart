import 'package:hive/hive.dart';

part 'quiz_result.g.dart';

@HiveType(typeId: 0)
class QuizResult extends HiveObject {
  @HiveField(0)
  String studentId;

  @HiveField(1)
  int score;

  @HiveField(2)
  int totalQuestions;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  List<String> studentAnswers;

  QuizResult({
    required this.studentId,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
    required this.studentAnswers,
  });
} 