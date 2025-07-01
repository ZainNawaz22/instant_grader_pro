import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _userPreferencesBox = 'user_preferences';
  static const String _schoolDataBox = 'school_data';
  
  static Future<void> initializeBoxes() async {
    await Hive.openBox(_userPreferencesBox);
    await Hive.openBox(_schoolDataBox);
  }
  
  static Box get _userPreferences => Hive.box(_userPreferencesBox);
  static Box get _schoolData => Hive.box(_schoolDataBox);
  
  static Future<void> saveUserPreference(String key, dynamic value) async {
    await _userPreferences.put(key, value);
  }
  
  static T? getUserPreference<T>(String key) {
    return _userPreferences.get(key) as T?;
  }
  
  static Future<void> saveSchoolData(String key, dynamic value) async {
    await _schoolData.put(key, value);
  }
  
  static T? getSchoolData<T>(String key) {
    return _schoolData.get(key) as T?;
  }
  
  static Future<void> clearUserPreferences() async {
    await _userPreferences.clear();
  }
  
  static Future<void> clearSchoolData() async {
    await _schoolData.clear();
  }
  
  static Future<void> deleteUserPreference(String key) async {
    await _userPreferences.delete(key);
  }
  
  static Future<void> deleteSchoolData(String key) async {
    await _schoolData.delete(key);
  }
  
  static Future<void> closeBoxes() async {
    await _userPreferences.close();
    await _schoolData.close();
  }
  
  static bool get isUserLoggedIn {
    return getUserPreference<bool>('isLoggedIn') ?? false;
  }
  
  static Future<void> setUserLoggedIn(bool value) async {
    await saveUserPreference('isLoggedIn', value);
  }
  
  static String? get currentUserRole {
    return getUserPreference<String>('userRole');
  }
  
  static Future<void> setCurrentUserRole(String role) async {
    await saveUserPreference('userRole', role);
  }
  
  static String? get schoolName {
    return getSchoolData<String>('schoolName');
  }
  
  static Future<void> setSchoolName(String name) async {
    await saveSchoolData('schoolName', name);
  }
} 