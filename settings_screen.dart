import 'package:material_ui/material_ui.dart';
import 'app_settings.dart';
import 'ksu_manager.dart';
import 'root_controller.dart';
import 'status_card.dart';
import 'strings.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _root = RootController.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _root.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _root.removeListener(_changed);
    super.dispose();
  }

  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _ask(String title, String body, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(S.cancel)),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _ensureRoot() async {
    if (_root.rootGranted) return true;
    final ok = await _root.requestRoot();
    if (!ok) _toast(_root.errorMessage ?? S.noRoot);
    return ok;
  }

  Future<void> _setAllModules(bool disabled) async {
    final accepted = await _ask(
      S.warningTitle,
      disabled ? '${S.disableAllBody}\n\n${S.bootLoopTip}' : S.enableAllBody,
      disabled ? S.disable : S.enable,
    );
    if (!accepted || !await _ensureRoot()) return;
    setState(() => _busy = true);
    try {
      final result = await KsuManager.instance.setAllModulesDisabled(disabled);
      final success = result['success'] == true;
      if (success) {
        await AppSettings.instance.setDisableModules(disabled);
        _root.addLog(disabled ? S.modulesDisabledLog : S.modulesEnabledLog);
      } else {
        _root.addLog('❌ ${(result['output'] ?? S.opFailedLog)}');
      }
      _toast(success ? S.commandDone : S.operationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeModule() async {
    final accepted = await _ask(S.removeModuleTitle, S.removeModuleBody, S.removeModule);
    if (!accepted || !await _ensureRoot()) return;
    final ok = await _root.removeFont();
    _toast(ok ? S.removeRequestSent : (_root.errorMessage ?? S.removeFailed));
  }

  Future<void> _attachFont() async {
    final message = await _root.importFont();
    if (message != null) _toast(message);
  }

  Future<void> _removeAttached() async {
    final accepted = await _ask(S.removeFontTitle, S.removeFontBody, S.delete);
    if (!accepted) return;
    await _root.resetImportedFont();
    _toast(S.fontRemoved);
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(color: AppTheme.appPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final fontLine = _root.fontReady
        ? '${S.fontAttached} (${formatBytes(_root.fontBytes)})'
        : S.fontNotAttached;
    return Scaffold(
      appBar: AppBar(title: Text(S.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _title(S.rootSection),
        ValueListenableBuilder<bool>(
          valueListenable: settings.autoSoftReboot,
          builder: (context, value, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(S.autoSoftReboot),
            subtitle: Text(S.autoSoftRebootSub),
            value: value,
            onChanged: settings.setAutoSoftReboot,
          ),
        ),
        const Divider(),
        ValueListenableBuilder<bool>(
          valueListenable: settings.disableModules,
          builder: (context, value, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(S.disableModules),
            subtitle: Text(S.disableModulesSub),
            value: value,
            onChanged: _busy ? null : _setAllModules,
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Text(S.bootLoopTip, style: const TextStyle(color: AppTheme.appWarning, height: 1.5)),
        ),
        const SizedBox(height: 22),
        _title(S.fontSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined, color: AppTheme.appPrimary),
              title: Text(fontLine),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded, color: AppTheme.appPrimary),
              title: Text(_root.fontReady ? S.changeFont : S.attachFont),
              onTap: _busy || _root.busy ? null : _attachFont,
            ),
            if (_root.customFont) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_rounded, color: AppTheme.appMuted),
                title: Text(S.removeFont),
                onTap: _busy || _root.busy ? null : _removeAttached,
              ),
            ],
            if (_root.fontInstalled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.appError),
                title: Text(S.removeModule, style: const TextStyle(color: AppTheme.appError)),
                onTap: _busy || _root.busy ? null : _removeModule,
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
