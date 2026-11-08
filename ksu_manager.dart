import 'package:flutter/services.dart';

class KsuManager {
  KsuManager._();
  static final instance = KsuManager._();
  static const _channel = MethodChannel('com.Bayan.emoji.app/root');

  Future<Map<String, dynamic>> _map(String method, [Map<String, dynamic>? args]) async {
    final value = await _channel.invokeMapMethod<String, dynamic>(method, args);
    return value ?? <String, dynamic>{};
  }

  Future<String> filesDir() async => (await _channel.invokeMethod<String>('getFilesDir')) ?? '';
  Future<int> versionCode() async => (await _channel.invokeMethod<int>('getVersionCode')) ?? 1;

  Future<Map<String, dynamic>> getDeviceInfo() => _map('getDeviceInfo');
  Future<Map<String, dynamic>> probeRoot() => _map('probeRoot');
  Future<Map<String, dynamic>> requestRoot() => _map('requestRoot');
  Future<Map<String, dynamic>> listModules() => _map('listModules');
  Future<Map<String, dynamic>> inspectFontArchive(String path) => _map('inspectFontArchive', {'path': path});
  Future<Map<String, dynamic>> importFont(String path) => _map('importFont', {'path': path});
  Future<Map<String, dynamic>> deleteCustom() => _map('deleteCustom');
  Future<Map<String, dynamic>> installModule(String path) => _map('installModule', {'path': path});
  Future<Map<String, dynamic>> removeModule(String moduleId) => _map('removeModule', {'moduleId': moduleId});
  Future<Map<String, dynamic>> setAllModulesDisabled(bool disabled) =>
      _map('setAllModulesDisabled', {'disabled': disabled});
  Future<Map<String, dynamic>> softReboot() => _map('softReboot');
}
