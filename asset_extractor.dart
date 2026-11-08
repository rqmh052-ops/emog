import 'dart:io';
import 'package:flutter/services.dart';
import 'ksu_manager.dart';

class AssetExtractor {
  AssetExtractor._();
  static final instance = AssetExtractor._();
  static const _assetPath = 'ios_emoji.zip';
  static const _baseName = 'ios_emoji.zip';
  static const _customName = 'custom_module.zip';
  String? _dir;
  String? lastError;

  Future<String> _filesDir() async => _dir ??= await KsuManager.instance.filesDir();

  /// ينسخ الموديل المرفق إلى مجلد التطبيق (ويعيد النسخ عند ترقية التطبيق).
  Future<void> prepare() async {
    try {
      final dir = await _filesDir();
      final target = File('$dir/$_baseName');
      final versionFile = File('$dir/asset_version.txt');
      final version = (await KsuManager.instance.versionCode()).toString();
      var stored = '';
      if (await versionFile.exists()) stored = (await versionFile.readAsString()).trim();
      final length = await target.exists() ? await target.length() : 0;
      if (length == 0 || stored != version) {
        final data = await rootBundle.load(_assetPath);
        await target.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        await versionFile.writeAsString(version, flush: true);
      }
      lastError = null;
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  Future<bool> hasCustom() async {
    final f = File('${await _filesDir()}/$_customName');
    return await f.exists() && await f.length() > 0;
  }

  /// الموديل المستورد إن وُجد، وإلا المرفق مع التطبيق.
  Future<String> activeModulePath() async {
    final dir = await _filesDir();
    if (await hasCustom()) return '$dir/$_customName';
    final base = File('$dir/$_baseName');
    if (!await base.exists() || await base.length() == 0) await prepare();
    return base.path;
  }

  /// مسار مؤقت داخل مجلد التطبيق لنقل الملف المختار إلى Kotlin.
  Future<String> importTempPath() async => '${await _filesDir()}/import_tmp';
}
