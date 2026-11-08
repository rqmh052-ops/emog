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
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text(S.cancel)),
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
      'تحذير',
      disabled
          ? 'سيتم تعطيل جميع موديلات مدير Root، بما فيها موديل خط الإيموجي. استخدم هذا الخيار للطوارئ فقط.\n\n${S.bootLoopTip}'
          : 'سيتم إعادة تفعيل جميع الموديلات. قد تعود المشكلة التي تسببت في حلقة الإقلاع.',
      disabled ? 'تعطيل' : 'تفعيل',
    );
    if (!accepted || !await _ensureRoot()) return;
    setState(() => _busy = true);
    try {
      final result = await KsuManager.instance.setAllModulesDisabled(disabled);
      final success = result['success'] == true;
      if (success) {
        await AppSettings.instance.setDisableModules(disabled);
        _root.addLog(disabled ? '⚠️ تم تعطيل جميع الموديلات (أعد التشغيل)' : '✅ تم إعادة تفعيل الموديلات (أعد التشغيل)');
      } else {
        _root.addLog('❌ ${(result['output'] ?? 'تعذر تنفيذ العملية')}');
      }
      _toast(success ? 'تم تنفيذ الأمر' : 'فشلت العملية');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFont() async {
    final accepted = await _ask(
      'إزالة موديل الخط',
      'سيتم إرسال أمر إزالة موديل iOS Emoji إلى مدير Root. تحتاج إلى إعادة تشغيل الجهاز لإزالة جميع آثاره.',
      S.remove,
    );
    if (!accepted || !await _ensureRoot()) return;
    final ok = await _root.removeFont();
    _toast(ok ? 'تم إرسال طلب الإزالة' : (_root.errorMessage ?? 'فشلت الإزالة'));
  }

  Future<void> _resetImported() async {
    final accepted = await _ask(
      'حذف الخط المستورد',
      'سيعود التطبيق إلى استخدام الموديل المرفق. الموديل المثبّت حالياً في الجهاز لا يتأثر.',
      'حذف',
    );
    if (!accepted) return;
    await _root.resetImportedFont();
    _toast('تم حذف الخط المستورد');
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(color: AppTheme.appPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text(S.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _title(S.rootSection),
        ValueListenableBuilder<bool>(
          valueListenable: settings.autoSoftReboot,
          builder: (context, value, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(S.autoSoftReboot),
            subtitle: const Text(S.autoSoftRebootSubtitle),
            value: value,
            onChanged: settings.setAutoSoftReboot,
          ),
        ),
        const Divider(),
        ValueListenableBuilder<bool>(
          valueListenable: settings.disableModules,
          builder: (context, value, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(S.disableModules),
            subtitle: const Text(S.disableModulesSubtitle),
            value: value,
            onChanged: _busy ? null : _setAllModules,
          ),
        ),
        const AppCard(
          padding: EdgeInsets.all(12),
          child: Text(S.bootLoopTip, style: TextStyle(color: AppTheme.appWarning, height: 1.5)),
        ),
        const SizedBox(height: 22),
        _title(S.fontSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined, color: AppTheme.appPrimary),
              title: const Text(S.fontTitle),
              subtitle: Text(
                'iOS 26.4 / Unicode 17  |  ${_root.fontInstalled ? S.fontInstalled : S.fontNotInstalled}\n'
                '${_root.customFont ? 'ملف مستورد' : 'الموديل المرفق'}  |  ${formatBytes(_root.fontBytes)}',
              ),
              isThreeLine: true,
              trailing: _root.fontInstalled
                  ? TextButton(
                      onPressed: _busy ? null : _removeFont,
                      child: const Text(S.remove, style: TextStyle(color: AppTheme.appError)),
                    )
                  : null,
            ),
            if (_root.customFont) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_rounded, color: AppTheme.appMuted),
                title: const Text('حذف الخط المستورد'),
                onTap: _busy ? null : _resetImported,
              ),
            ],
          ]),
        ),
        const SizedBox(height: 22),
        _title(S.aboutSection),
        const AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(title: Text('الإصدار'), trailing: Text(S.appVersion)),
            Divider(height: 1),
            ListTile(title: Text('طريقة Root'), subtitle: Text('طلب صلاحية من المدير المثبت فقط')),
            Divider(height: 1),
            ListTile(title: Text('مدير الوحدات'), subtitle: Text('KernelSU أو APatch أو Magisk عند توفر أمره')),
            Divider(height: 1),
            ListTile(title: Text('الاتصال بالإنترنت'), subtitle: Text('لا يوجد: التطبيق بلا صلاحية INTERNET')),
          ]),
        ),
        const SizedBox(height: 12),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
