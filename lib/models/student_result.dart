import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class StudentResult extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String rollNumber;
  
  @HiveField(2)
  final String? studentName;
  
  @HiveField(3)
  final String answerKeyId;
  
  @HiveField(4)
  final List<String?> studentAnswers;
  
  @HiveField(5)
  final double score;
  
  @HiveField(6)
  final double maxScore;
  
  @HiveField(7)
  final DateTime examDate;
  
  @HiveField(8)
  final Map<int, bool> correctnessMap;

  StudentResult({
    required this.id,
    required this.rollNumber,
    this.studentName,
    required this.answerKeyId,
    required this.studentAnswers,
    required this.score,
    required this.maxScore,
    required this.examDate,
    required this.correctnessMap,
  });

  double get percentage => (score / maxScore) * 100;
  
  String get grade {
    final percentage = this.percentage;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
  
  int get totalCorrect => correctnessMap.values.where((v) => v).length;
  int get totalIncorrect => correctnessMap.values.where((v) => !v).length;
  int get totalUnanswered => studentAnswers.where((a) => a == null).length;
  
  // Manual serialization methods
  Map<String, dynamic> toJson() => {
    'id': id,
    'rollNumber': rollNumber,
    'studentName': studentName,
    'answerKeyId': answerKeyId,
    'studentAnswers': studentAnswers,
    'score': score,
    'maxScore': maxScore,
    'examDate': examDate.toIso8601String(),
    'correctnessMap': correctnessMap.map((k, v) => MapEntry(k.toString(), v)),
  };
  
  factory StudentResult.fromJson(Map<String, dynamic> json) => StudentResult(
    id: json['id'],
    rollNumber: json['rollNumber'],
    studentName: json['studentName'],
    answerKeyId: json['answerKeyId'],
    studentAnswers: List<String?>.from(json['studentAnswers']),
    score: json['score']?.toDouble() ?? 0.0,
    maxScore: json['maxScore']?.toDouble() ?? 0.0,
    examDate: DateTime.parse(json['examDate']),
    correctnessMap: Map<int, bool>.from(
      (json['correctnessMap'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v as bool))
    ),
  );
} 