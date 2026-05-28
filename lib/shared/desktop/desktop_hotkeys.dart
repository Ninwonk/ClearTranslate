import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../domain/entities/app_settings.dart';

class DesktopHotKeys {
  const DesktopHotKeys._();

  static HotKey defaultShowWindow() {
    return HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: [_primaryModifier(), HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );
  }

  static HotKey defaultClearInput() {
    return HotKey(
      key: PhysicalKeyboardKey.keyL,
      modifiers: [_primaryModifier(), HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );
  }

  static HotKey showWindow(AppSettings settings) {
    return _fromJson(settings.showWindowHotKey) ?? defaultShowWindow();
  }

  static HotKey clearInput(AppSettings settings) {
    return _fromJson(settings.clearInputHotKey) ?? defaultClearInput();
  }

  static Map<String, Object?> toJson(HotKey hotKey) {
    return hotKey.toJson().cast<String, Object?>();
  }

  static String label(HotKey hotKey) {
    final parts = [
      for (final modifier in hotKey.modifiers ?? []) _modifierLabel(modifier),
      hotKey.physicalKey.keyLabel,
    ];
    return parts.join(' + ');
  }

  static HotKey? _fromJson(Map<String, Object?>? json) {
    if (json == null) {
      return null;
    }
    try {
      return HotKey.fromJson(json.cast<String, dynamic>());
    } on Object catch (error) {
      debugPrint('Invalid hotkey setting: $error');
      return null;
    }
  }

  static HotKeyModifier _primaryModifier() {
    return Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control;
  }

  static String _modifierLabel(HotKeyModifier modifier) {
    return switch (modifier) {
      HotKeyModifier.control => Platform.isMacOS ? '⌃' : 'Ctrl',
      HotKeyModifier.meta => Platform.isMacOS ? '⌘' : 'Win',
      HotKeyModifier.alt => Platform.isMacOS ? '⌥' : 'Alt',
      HotKeyModifier.shift => Platform.isMacOS ? '⇧' : 'Shift',
      HotKeyModifier.capsLock => 'CapsLock',
      HotKeyModifier.fn => 'Fn',
    };
  }
}
