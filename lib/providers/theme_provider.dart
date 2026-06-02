import 'package:flutter/foundation.dart';

class ThemeProvider extends ChangeNotifier {
  bool darkMode = false;
  void toggle() {
    darkMode = !darkMode;
    notifyListeners();
  }
}
