import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'app_settings.dart';
import 'asset_extractor.dart';
import 'ksu_manager.dart';
import 'strings.dart';

class RootController extends ChangeNotifier {
  RootController._();
  static final instance = RootController._();

  static const moduleId = 'iOS26.4Unicode17';
  static const minFontBytes = 10000;
  static const _maxLogLines = 500;

  bool rootGranted = false;
  bool fontInstalled = false;
  bool hasMetamodule = true;
  bool busy = false;
  bool customFont = false;
  int fontBytes = -1;
  String status = S.rootUnknown;
  String managerName = 'غير معروف';
  String manufacturer = '—';
  String model = '—';
  String androidVersion = '—';
  String kernelVersion = '—';
  String? errorMessage;
  final List<String> logs = <String>[];

  File? _logFile;
  Future<void> _logChain = Future<void>.value();
  bool _initialized = false;

  bool get fontReady => fontBytes >= minFontBytes;

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
  }

  void _log(String message) {
    final line = '[${_stamp()}] $message';
    logs.add(line);
    if (logs.length > _maxLogLines) logs.removeRange(0, logs.length - _maxLogLines);
    _logChain = _logChain.then((_) async {
      try {
        await _logFile?.writeAsString('$line\n', mode: FileMode.append);
      } catch (_) {}
    });
    notifyListeners();
  }

  void addLog(String message) => _log(message);

  Future<void> clearLogs() async {
    logs.clear();
    _logChain = _logChain.then((_) async {
      try {
        await _logFile?.writeAsString('');
      } catch (_) {}
    });
    notifyListeners();
  }

  Future<void> _loadLogs() async {
    try {
      final dir = await KsuManager.instance.filesDir();
      _logFile = File('$dir/app_log.txt');
      if (await _logFile!.exists()) {
        final lines = (await _logFile!.readAsLines()).where((l) => l.trim().isNotEmpty).toList();
        final keep = lines.length > _maxLogLines ? lines.sublist(lines.length - _maxLogLines) : lines;
        logs.addAll(keep);
        if (keep.length != lines.length) {
          await _logFile!.writeAsString('${keep.join('\n')}\n');
        }
      }
    } catch (_) {}
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadLogs();
    try {
      final info = await KsuManager.instance.getDeviceInfo();
      manufacturer = (info['manufacturer'] ?? '—').toString();
      model = (info['model'] ?? '—').toString();
      androidVersion = (info['androidVersion'] ?? '—').toString();
      kernelVersion = (info['kernelVersion'] ?? '—').toString();
      final probe = await KsuManager.instance.probeRoot();
      managerName = (probe['manager'] ?? 'غير معروف').toString();
      _log('✅ تم تحميل معلومات الجهاز');
      _log('ℹ️ مدير Root المحتمل: $managerName');
    } catch (e) {
      _log('⚠️ تعذر قراءة بعض معلومات الجهاز: $e');
    }
    fontInstalled = AppSettings.instance.fontInstalled.value;
    await refreshFontInfo();
  }

  Future<void> refreshFontInfo() async {
    try {
      customFont = await AssetExtractor.instance.hasCustom();
      final path = await AssetExtractor.instance.activeModulePath();
      final info = await KsuManager.instance.inspectFontArchive(path);
      fontBytes = info['fontSize'] is int ? info['fontSize'] as int : -1;
    } catch (_) {
      fontBytes = -1;
    }
    notifyListeners();
  }

  Future<bool> requestRoot() async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    status = 'جارٍ طلب صلاحية Root…';
    _log('🔍 جارٍ التحقق من صلاحية Root');
    notifyListeners();
    try {
      final result = await KsuManager.instance.requestRoot();
      rootGranted = result['granted'] == true;
      final output = (result['output'] ?? '').toString().trim();
      if (!rootGranted) {
        status = S.rootInactive;
        errorMessage = output.isEmpty ? S.noRoot : output;
        _log('❌ $status');
        if (output.isNotEmpty) _log(output);
        return false;
      }
      status = S.rootActive;
      managerName = (result['manager'] ?? managerName).toString();
      _log('✅ تم منح التطبيق صلاحية Root ($managerName)');
      await refreshModuleState();
      return true;
    } catch (e) {
      rootGranted = false;
      status = 'تعذر طلب Root';
      errorMessage = e.toString();
      _log('❌ فشل طلب Root: $e');
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshModuleState() async {
    if (!rootGranted) return;
    final result = await KsuManager.instance.listModules();
    final output = (result['output'] ?? '').toString();
    fontInstalled = result['success'] == true && output.contains(moduleId);
    hasMetamodule = managerName != 'KernelSU' || output.contains('APP_METAMODULE:');
    await AppSettings.instance.setFontInstalled(fontInstalled);
    _log(fontInstalled ? '✅ موديل خط iPhone Emoji مثبت' : 'ℹ️ موديل خط iPhone Emoji غير مثبت');
    if (managerName == 'KernelSU' && !hasMetamodule) {
      _log('⚠️ لا يوجد Metamodule في KernelSU؛ لن يُركّب مجلد system');
    }
    notifyListeners();
  }

  Future<bool> installFont() async {
    if (!rootGranted || busy) return false;
    busy = true;
    status = 'جارٍ تثبيت موديل الخط…';
    errorMessage = null;
    _log('📦 جارٍ تجهيز موديل خط iPhone Emoji');
    notifyListeners();
    try {
      final path = await AssetExtractor.instance.activeModulePath();
      final result = await KsuManager.instance.installModule(path);
      final success = result['success'] == true;
      final output = (result['output'] ?? '').toString().trim();
      if (!success) {
        status = 'فشل تثبيت الموديل';
        errorMessage = output.isEmpty ? 'تعذر تثبيت الموديل. تحقق من صلاحية Root ومدير الوحدات.' : output;
        _log('❌ فشل تثبيت موديل الخط');
        if (output.isNotEmpty) _log(output);
        return false;
      }
      fontInstalled = true;
      await AppSettings.instance.setFontInstalled(true);
      status = 'تم تثبيت الموديل';
      _log('✅ تم تثبيت الموديل عبر مدير Root');
      if (output.isNotEmpty) _log(output);
      _log('ℹ️ أعد تشغيل الواجهة أو الجهاز لتطبيق التغييرات');
      return true;
    } catch (e) {
      status = 'فشل تثبيت الموديل';
      errorMessage = e.toString();
      _log('❌ خطأ أثناء تثبيت الموديل: $e');
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> removeFont() async {
    if (!rootGranted || busy) return false;
    busy = true;
    notifyListeners();
    try {
      final result = await KsuManager.instance.removeModule(moduleId);
      final success = result['success'] == true;
      final output = (result['output'] ?? '').toString().trim();
      if (success) {
        fontInstalled = false;
        await AppSettings.instance.setFontInstalled(false);
        _log('✅ تم إرسال طلب إزالة موديل الخط (يكتمل بعد إعادة التشغيل)');
      } else {
        errorMessage = output.isEmpty ? 'تعذرت إزالة الموديل' : output;
        _log('❌ فشلت إزالة موديل الخط');
        if (output.isNotEmpty) _log(output);
      }
      return success;
    } catch (e) {
      errorMessage = e.toString();
      _log('❌ خطأ أثناء إزالة الموديل: $e');
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// يفتح منتقي الملفات: ملف خط ‎.ttf‎ أو موديل ‎.zip‎ جاهز.
  /// يرجع رسالة نجاح أو خطأ، أو null عند الإلغاء.
  Future<String?> importFont() async {
    if (busy) return null;
    busy = true;
    notifyListeners();
    try {
      final PlatformFile? picked = await FilePicker.pickFile(type: FileType.any);
      if (picked == null) return null;
      _log('📦 جارٍ استيراد: ${picked.name}');
      final tmp = File(await AssetExtractor.instance.importTempPath());
      await tmp.writeAsBytes(await picked.readAsBytes(), flush: true);
      final result = await KsuManager.instance.importFont(tmp.path);
      if (await tmp.exists()) await tmp.delete();
      if (result['success'] != true) {
        final err = (result['error'] ?? 'فشل الاستيراد').toString();
        _log('❌ $err');
        return err;
      }
      await refreshFontInfo();
      _log('✅ تم استيراد الخط (${formatBytes(fontBytes)})');
      return fontInstalled
          ? 'تم الاستيراد. أعد تثبيت الموديل ليستخدم الخط الجديد.'
          : 'تم استيراد الخط بنجاح.';
    } catch (e) {
      _log('❌ فشل الاستيراد: $e');
      return 'فشل الاستيراد: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resetImportedFont() async {
    await KsuManager.instance.deleteCustom();
    await refreshFontInfo();
    _log('ℹ️ تم حذف الخط المستورد والرجوع للموديل المرفق');
  }
}

String formatBytes(int bytes) {
  if (bytes < 0) return 'غير معروف';
  if (bytes < 1024) return '$bytes بايت';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} ك.ب';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
}
