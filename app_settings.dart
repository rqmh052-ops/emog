import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ksu_manager.dart';

/// إعدادات محلية في ملف JSON داخل مجلد التطبيق (بدون أي مكتبات إضافية).
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final ValueNotifier<bool> autoSoftReboot = ValueNotifier<bool>(true);
  final ValueNotifier<bool> disableModules = ValueNotifier<bool>(false);
  final ValueNotifier<bool> fontInstalled = ValueNotifier<bool>(false);
  File? _file;

  Future<void> initialize() async {
    try {
      final dir = await KsuManager.instance.filesDir();
      _file = File('$dir/settings.json');
      if (await _file!.exists()) {
        final data = jsonDecode(await _file!.readAsString());
        if (data is Map) {
          autoSoftReboot.value = data['autoSoftReboot'] != false;
          disableModules.value = data['disableModules'] == true;
          fontInstalled.value = data['fontInstalled'] == true;
        }
      }
    } catch (_) {
      // تبقى القيم الافتراضية.
    }
  }

  Future<void> _save() async {
    try {
      await _file?.writeAsString(jsonEncode({
        'autoSoftReboot': autoSoftReboot.value,
        'disableModules': disableModules.value,
        'fontInstalled': fontInstalled.value,
      }));
    } catch (_) {}
  }

  Future<void> setAutoSoftReboot(bool v) async {
    autoSoftReboot.value = v;
    await _save();
  }

  Future<void> setDisableModules(bool v) async {
    disableModules.value = v;
    await _save();
  }

  Future<void> setFontInstalled(bool v) async {
    fontInstalled.value = v;
    await _save();
  }
}
