import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../domain/entities/app_settings.dart';
import 'desktop_commands.dart';
import 'desktop_hotkeys.dart';

class DesktopIntegration with WindowListener, TrayListener {
  DesktopIntegration._();

  static final DesktopIntegration instance = DesktopIntegration._();

  bool _isInitialized = false;
  bool _isQuitting = false;
  DateTime? _lastTrayMenuPopupAt;

  bool get isSupported => !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  Future<void> initialize(AppSettings settings) async {
    if (_isInitialized || !isSupported) {
      return;
    }

    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    windowManager.addListener(this);
    trayManager.addListener(this);

    await _setupTray();
    await configureHotKeys(settings);

    _isInitialized = true;
  }

  Future<void> _setupTray() async {
    final iconPath = Platform.isWindows
        ? 'assets/tray/tray_icon.ico'
        : 'assets/tray/tray_icon.png';
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('ClearTranslate');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: '打开 ClearTranslate'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: '退出'),
        ],
      ),
    );
  }

  Future<void> configureHotKeys(AppSettings settings) async {
    if (!isSupported) {
      return;
    }
    await hotKeyManager.unregisterAll();

    await _tryRegisterHotKey(
      DesktopHotKeys.showWindow(settings),
      (_) => showTranslateWindow(),
    );

    await _tryRegisterHotKey(
      DesktopHotKeys.clearInput(settings),
      (_) => DesktopCommands.instance.requestClearInput(),
    );
  }

  Future<void> _tryRegisterHotKey(
    HotKey hotKey,
    HotKeyHandler handler,
  ) async {
    try {
      await hotKeyManager.register(hotKey, keyDownHandler: handler);
    } on Object catch (error) {
      debugPrint('Failed to register hotkey ${hotKey.debugName}: $error');
    }
  }

  Future<void> showTranslateWindow() async {
    await windowManager.show();
    await windowManager.focus();
    DesktopCommands.instance.requestShowTranslate();
  }

  Future<void> _hideToTray() async {
    await windowManager.hide();
  }

  Future<void> quit() async {
    _isQuitting = true;
    await hotKeyManager.unregisterAll();
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  void onWindowClose() {
    if (_isQuitting) {
      return;
    }
    _hideToTray();
  }

  @override
  void onTrayIconMouseDown() {
    showTranslateWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    _showTrayMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    _showTrayMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await showTranslateWindow();
      case 'quit':
        await quit();
    }
  }

  void _showTrayMenu() {
    final now = DateTime.now();
    final last = _lastTrayMenuPopupAt;
    if (last != null && now.difference(last).inMilliseconds < 500) {
      return;
    }
    _lastTrayMenuPopupAt = now;
    trayManager.popUpContextMenu();
  }
}
