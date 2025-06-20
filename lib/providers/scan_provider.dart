import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/quiz_result.dart';

class ScanProvider extends ChangeNotifier {
  List<QuizResult> _scanHistory = [];
  Map<String, List<String>> _answerKeys = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<QuizResult> get scanHistory => _scanHistory;
  Map<String, List<String>> get answerKeys => _answerKeys;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final scanHistoryBox = Hive.box('scan_history');
      final answerKeysBox = Hive.box('answer_keys');

      _scanHistory = scanHistoryBox.values.cast<QuizResult>().toList();
      
      final rawAnswerKeys = answerKeysBox.toMap();
      _answerKeys = rawAnswerKeys.map((key, value) => 
          MapEntry(key.toString(), List<String>.from(value)));

    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuizResult(QuizResult result) async {
    try {
      final box = Hive.box('scan_history');
      await box.add(result);
      _scanHistory.add(result);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save quiz result: $e';
      notifyListeners();
    }
  }

  Future<void> saveAnswerKey(String quizId, List<String> answers) async {
    try {
      final box = Hive.box('answer_keys');
      await box.put(quizId, answers);
      _answerKeys[quizId] = answers;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save answer key: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    try {
      final scanHistoryBox = Hive.box('scan_history');
      final answerKeysBox = Hive.box('answer_keys');
      
      await scanHistoryBox.clear();
      await answerKeysBox.clear();
      
      _scanHistory.clear();
      _answerKeys.clear();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear data: $e';
      notifyListeners();
    }
  }
} 