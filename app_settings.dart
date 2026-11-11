import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'ksu_manager.dart';

/// إعدادات محلية في ملف JSON (بدون مكتبات خارجية).
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // ── إعدادات موجودة ──────────────────────────────────────────────────────
  final ValueNotifier<bool> autoSoftReboot  = ValueNotifier<bool>(true);
  final ValueNotifier<bool> disableModules  = ValueNotifier<bool>(false);
  final ValueNotifier<bool> fontInstalled   = ValueNotifier<bool>(false);
  final ValueNotifier<String> language      = ValueNotifier<String>('ar');

  // ── إعدادات الـ Exploit (DFRoot) — مطفأة بالافتراضي ────────────────────
  /// التشغيل عند الإقلاع: يُعيد تشغيل الـ Exploit تلقائياً بعد إقلاع الجهاز
  final ValueNotifier<bool> exploitStartOnBoot      = ValueNotifier<bool>(false);
  /// إعادة تشغيل الواجهة تلقائياً بعد نجاح الـ Exploit
  final ValueNotifier<bool> exploitAutoSoftReboot   = ValueNotifier<bool>(false);

  File? _file;

  Future<void> initialize() async {
    try {
      final dir = await KsuManager.instance.filesDir();
      _file = File('$dir/settings.json');
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        if (raw.isNotEmpty) {
          final data = jsonDecode(raw);
          if (data is Map) {
            autoSoftReboot.value       = data['autoSoftReboot'] != false;
            disableModules.value       = data['disableModules'] == true;
            fontInstalled.value        = data['fontInstalled'] == true;
            language.value             = (data['language'] as String?) ?? 'ar';
            exploitStartOnBoot.value   = data['exploitStartOnBoot'] == true;
            exploitAutoSoftReboot.value= data['exploitAutoSoftReboot'] == true;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _file?.writeAsString(jsonEncode({
        'autoSoftReboot':        autoSoftReboot.value,
        'disableModules':        disableModules.value,
        'fontInstalled':         fontInstalled.value,
        'language':              language.value,
        'exploitStartOnBoot':    exploitStartOnBoot.value,
        'exploitAutoSoftReboot': exploitAutoSoftReboot.value,
      }));
    } catch (_) {}
  }

  Future<void> setAutoSoftReboot(bool v)        async { autoSoftReboot.value = v;        await _save(); }
  Future<void> setDisableModules(bool v)         async { disableModules.value = v;         await _save(); }
  Future<void> setFontInstalled(bool v)          async { fontInstalled.value = v;          await _save(); }
  Future<void> setLanguage(String v)             async { language.value = v;               await _save(); }
  Future<void> setExploitStartOnBoot(bool v)     async { exploitStartOnBoot.value = v;     await _save(); }
  Future<void> setExploitAutoSoftReboot(bool v)  async { exploitAutoSoftReboot.value = v;  await _save(); }
}
