import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

class PosWindow {
  static final Set<int> _windowIds = <int>{};

  static Future<void> open({bool reuseExisting = false}) async {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (!isDesktop) {
      Get.toNamed('/pos');
      return;
    }

    await _cleanupClosedWindows();

    if (reuseExisting && _windowIds.isNotEmpty) {
      try {
        final targetWindowId = _windowIds.last;
        final controller = WindowController.fromWindowId(targetWindowId);
        await controller.show();
        return;
      } catch (_) {
        await _cleanupClosedWindows();
      }
    }

    try {
      final window = await DesktopMultiWindow.createWindow('/pos');
      _windowIds.add(window.windowId);
      await window.setFrame(const Offset(100, 100) & const Size(1280, 800));
      await window.center();
      await window.setTitle('POS');
      await window.show();
    } on MissingPluginException {
      Get.toNamed('/pos');
    }
  }

  static Future<void> _cleanupClosedWindows() async {
    try {
      final ids = await DesktopMultiWindow.getAllSubWindowIds();
      _windowIds.removeWhere((id) => !ids.contains(id));
    } catch (_) {
      _windowIds.clear();
    }
  }
}
