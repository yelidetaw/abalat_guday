import 'package:flutter/material.dart';

class GradeProvider extends ChangeNotifier {
  int _refreshKey = 0;
  int get refreshKey => _refreshKey;

  /// Call this method to signal that the grade screen should refresh its data.
  void triggerRefresh() {
    _refreshKey++;
    notifyListeners();
  }
}