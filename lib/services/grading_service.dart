import 'package:hive_flutter/hive_flutter.dart';
import 'package:instant_grader_pro/models/answer_key.dart';
import 'package:instant_grader_pro/models/student_result.dart';
import 'package:instant_grader_pro/omr_engine/models/omr_result.dart';

class GradingService {
  static const String answerKeyBoxName = 'answer_keys';
  static const String studentResultBoxName = 'student_results';
  
  late Box _answerKeyBox;
  late Box _studentResultBox;
  
  Future<void> init() async {
    _answerKeyBox = await Hive.openBox(answerKeyBoxName);
    _studentResultBox = await Hive.openBox(studentResultBoxName);
  }
  
  // Answer Key Management
  Future<void> saveAnswerKey(AnswerKey answerKey) async {
    await _answerKeyBox.put(answerKey.id, answerKey.toJson());
  }
  
  AnswerKey? getAnswerKey(String id) {
    final json = _answerKeyBox.get(id);
    if (json == null) return null;
    return AnswerKey.fromJson(Map<String, dynamic>.from(json));
  }
  
  List<AnswerKey> getAllAnswerKeys() {
    return _answerKeyBox.values
        .map((json) => AnswerKey.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
  
  Future<void> deleteAnswerKey(String id) async {
    await _answerKeyBox.delete(id);
  }
  
  // Student Result Management
  Future<StudentResult> gradeStudent({
    required String rollNumber,
    String? studentName,
    required String answerKeyId,
    required List<OmrResult> omrResults,
  }) async {
    final answerKey = getAnswerKey(answerKeyId);
    if (answerKey == null) {
      throw Exception('Answer key not found');
    }
    
    // Convert OMR results to student answers
    final studentAnswers = _convertOmrToAnswers(omrResults, answerKey.totalQuestions);
    
    // Calculate score and correctness
    final correctnessMap = <int, bool>{};
    double score = 0;
    
    for (int i = 0; i < answerKey.correctAnswers.length; i++) {
      if (i < studentAnswers.length && studentAnswers[i] != null) {
        final isCorrect = answerKey.correctAnswers[i] == studentAnswers[i];
        correctnessMap[i] = isCorrect;
        if (isCorrect) {
          score += answerKey.marksPerQuestion;
        }
      }
    }
    
    // Create and save result
    final result = StudentResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rollNumber: rollNumber,
      studentName: studentName,
      answerKeyId: answerKeyId,
      studentAnswers: studentAnswers,
      score: score,
      maxScore: answerKey.maxScore,
      examDate: DateTime.now(),
      correctnessMap: correctnessMap,
    );
    
    await _studentResultBox.put(result.id, result.toJson());
    return result;
  }
  
  List<StudentResult> getStudentResults({String? rollNumber, String? answerKeyId}) {
    var results = _studentResultBox.values
        .map((json) => StudentResult.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    
    if (rollNumber != null) {
      results = results.where((r) => r.rollNumber == rollNumber).toList();
    }
    
    if (answerKeyId != null) {
      results = results.where((r) => r.answerKeyId == answerKeyId).toList();
    }
    
    return results;
  }
  
  // Convert OMR bubble detection results to answer choices (A, B, C, D, etc.)
  List<String?> _convertOmrToAnswers(List<OmrResult> omrResults, int totalQuestions) {
    final answers = List<String?>.filled(totalQuestions, null);
    
    // Group OMR results by row (question number)
    final groupedByRow = <int, List<OmrResult>>{};
    for (final result in omrResults) {
      if (result.isMarked) {
        groupedByRow.putIfAbsent(result.rowIndex, () => []).add(result);
      }
    }
    
    // Convert column index to answer choice
    groupedByRow.forEach((row, marks) {
      if (row < totalQuestions && marks.isNotEmpty) {
        // Find the mark with highest confidence if multiple marks
        marks.sort((a, b) => b.confidence.compareTo(a.confidence));
        final bestMark = marks.first;
        
        // Convert column index to letter (0=A, 1=B, 2=C, 3=D, etc.)
        answers[row] = String.fromCharCode('A'.codeUnitAt(0) + bestMark.colIndex);
      }
    });
    
    return answers;
  }
  
  // Analytics
  Map<String, dynamic> getTestStatistics(String answerKeyId) {
    final results = getStudentResults(answerKeyId: answerKeyId);
    if (results.isEmpty) {
      return {'error': 'No results found for this test'};
    }
    
    final scores = results.map((r) => r.score).toList();
    final percentages = results.map((r) => r.percentage).toList();
    
    scores.sort();
    percentages.sort();
    
    return {
      'totalStudents': results.length,
      'averageScore': scores.reduce((a, b) => a + b) / scores.length,
      'averagePercentage': percentages.reduce((a, b) => a + b) / percentages.length,
      'highestScore': scores.last,
      'lowestScore': scores.first,
      'medianScore': scores[scores.length ~/ 2],
      'passCount': results.where((r) => r.percentage >= 50).length,
      'failCount': results.where((r) => r.percentage < 50).length,
    };
  }
} 