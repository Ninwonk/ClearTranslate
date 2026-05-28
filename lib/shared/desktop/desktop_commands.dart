import 'package:flutter/foundation.dart';

class DesktopCommands {
  DesktopCommands._();

  static final DesktopCommands instance = DesktopCommands._();

  final ValueNotifier<int> showTranslateRequests = ValueNotifier<int>(0);
  final ValueNotifier<int> clearInputRequests = ValueNotifier<int>(0);

  void requestShowTranslate() {
    showTranslateRequests.value++;
  }

  void requestClearInput() {
    clearInputRequests.value++;
  }
}
