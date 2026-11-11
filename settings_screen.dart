import 'package:material_ui/material_ui.dart';
import 'app_settings.dart';
import 'exploit_engine.dart';
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
  final _root    = RootController.instance;
  final _exploit = ExploitEngine.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _root.addListener(_rebuild);
    _exploit.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _root.removeListener(_rebuild);
    _exploit.removeListener(_rebuild);
    super.dispose();
  }

  void _toast(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _ask(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
          ],
        ),
      ) ?? false;

  Future<bool> _ensureRoot() async {
    if (_root.rootGranted) return true;
    final ok = await _root.requestRoot();
    if (!ok) _toast(_root.errorMessage ?? S.noRoot);
    return ok;
  }

  Future<void> _setAllModules(bool disabled) async {
    final ok = await _ask(
      S.warningTitle,
      disabled ? S.disableAllBody : S.enableAllBody,
      disabled ? S.disable : S.enable,
    );
    if (!ok || !await _ensureRoot()) return;
    setState(() => _busy = true);
    try {
      final r = await KsuManager.instance.setAllModulesDisabled(disabled);
      final success = r['success'] == true;
      _root.addLog(success
          ? (disabled ? S.modulesDisabledLog : S.modulesEnabledLog)
          : '❌ ${r['output'] ?? S.opFailedLog}');
      _toast(success ? S.commandDone : S.operationFailed);
      if (success) await AppSettings.instance.setDisableModules(disabled);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFont() async {
    if (!await _ask(S.removeModuleTitle, S.removeModuleBody, S.removeModule)) return;
    if (!await _ensureRoot()) return;
    final ok = await _root.removeFont();
    _toast(ok ? S.removeRequestSent : (_root.errorMessage ?? S.removeFailed));
  }

  Future<void> _resetImported() async {
    if (!await _ask(S.removeFontTitle, S.removeFontBody, S.delete)) return;
    await _root.resetImportedFont();
    _toast(S.fontRemoved);
  }

  // ── Exploit helpers ─────────────────────────────────────────────────────

  Future<void> _runExploit() async {
    if (_exploit.status.isRunning) return;
    _exploit.logs.clear();
    await _exploit.runFull();
    if (!mounted) return;
    final phase = _exploit.status.phase;
    if (phase == ExploitPhase.success) {
      _toast('✅ Root نشط! يمكنك الآن تثبيت موديل الخط من الرئيسية');
      _root.initialize(); // تحديث حالة الروت في الشاشة الرئيسية
    } else if (phase == ExploitPhase.failed) {
      _toast(_exploit.status.error ?? 'فشل الـ Exploit');
    }
  }

  Future<void> _grantSelfRoot() async {
    if (!_exploit.status.ksudActive) {
      _toast('فعّل الروت أولاً بالخطوة السابقة');
      return;
    }
    final ok = await _exploit.grantSelfRoot();
    _toast(ok ? '✅ تم منح الصلاحية لهذا التطبيق' : '❌ فشل منح الصلاحية');
  }

  // ── UI helpers ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(text,
        style: const TextStyle(
            color: AppTheme.appPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
  );

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text,
        style: const TextStyle(color: AppTheme.appWarning, fontSize: 12.5, height: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final exploit  = _exploit.status;
    return Scaffold(
      appBar: AppBar(title: Text(S.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ══════════════════════════════════════════════════════════════════
        // قسم تفعيل الروت الكيرنلي (DFRoot + KernelSU)
        // ══════════════════════════════════════════════════════════════════
        _sectionTitle('تفعيل الروت الكيرنلي (DFRoot)'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [

            // ── حالة الـ Exploit ──────────────────────────────────────────
            if (exploit.kmi != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  const Text('KMI: ', style: TextStyle(color: AppTheme.appMuted)),
                  Text(exploit.kmi!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),

            // ── زر تفعيل الروت (DFRoot) ──────────────────────────────────
            ListTile(
              leading: Icon(
                exploit.phase == ExploitPhase.success
                    ? Icons.verified_rounded
                    : exploit.phase == ExploitPhase.failed
                        ? Icons.error_outline_rounded
                        : Icons.security_rounded,
                color: exploit.phase == ExploitPhase.success
                    ? AppTheme.appSuccess
                    : exploit.phase == ExploitPhase.failed
                        ? AppTheme.appError
                        : AppTheme.appPrimary,
              ),
              title: const Text('① تفعيل الروت',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_exploit.phaseLabel,
                  style: TextStyle(
                    color: exploit.phase == ExploitPhase.success
                        ? AppTheme.appSuccess
                        : exploit.phase == ExploitPhase.failed
                            ? AppTheme.appError
                            : AppTheme.appMuted,
                  )),
              trailing: exploit.isRunning
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.appPrimary))
                  : FilledButton(
                      onPressed: _runExploit,
                      child: Text(
                        exploit.phase == ExploitPhase.success
                            ? 'أعد'
                            : exploit.phase == ExploitPhase.failed
                                ? 'أعد المحاولة'
                                : 'تفعيل',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
            ),

            const Divider(height: 1),

            // ── منح الصلاحية لهذا التطبيق (KernelSU) ─────────────────────
            ListTile(
              leading: Icon(
                exploit.rootGranted
                    ? Icons.admin_panel_settings_rounded
                    : Icons.admin_panel_settings_outlined,
                color: exploit.rootGranted
                    ? AppTheme.appSuccess
                    : AppTheme.appMuted,
              ),
              title: const Text('② منح Root لهذا التطبيق (KernelSU)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                exploit.rootGranted
                    ? '✅ الصلاحية ممنوحة'
                    : exploit.ksudActive
                        ? 'اضغط لمنح الصلاحية تلقائياً'
                        : 'فعّل الروت بالخطوة ① أولاً',
                style: TextStyle(
                  color: exploit.rootGranted
                      ? AppTheme.appSuccess
                      : AppTheme.appMuted,
                ),
              ),
              trailing: !exploit.rootGranted
                  ? FilledButton(
                      onPressed: exploit.ksudActive ? _grantSelfRoot : null,
                      child: const Text('منح', style: TextStyle(fontSize: 13)),
                    )
                  : const Icon(Icons.check_circle_rounded, color: AppTheme.appSuccess),
            ),

            const Divider(height: 1),

            // ── سجل الـ Exploit المصغّر ───────────────────────────────────
            if (_exploit.logs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _exploit.logs.length,
                    itemBuilder: (_, i) {
                      final line = _exploit.logs[i];
                      return Text(line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: line.contains('❌')
                                ? AppTheme.appError
                                : line.contains('✅')
                                    ? AppTheme.appSuccess
                                    : line.contains('⚠️')
                                        ? AppTheme.appWarning
                                        : AppTheme.appMuted,
                          ));
                    },
                  ),
                ),
              ),
          ]),
        ),

        const SizedBox(height: 8),

        // ── إعدادات DFRoot ───────────────────────────────────────────────
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [

            // التشغيل عند الإقلاع
            ValueListenableBuilder<bool>(
              valueListenable: settings.exploitStartOnBoot,
              builder: (_, v, __) => SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('التشغيل عند الإقلاع'),
                subtitle: const Text(
                    'يُعيد تفعيل الروت تلقائياً بعد كل إعادة تشغيل للجهاز'),
                value: v,
                onChanged: (nv) async {
                  if (nv) {
                    final ok = await _ask(
                      'تفعيل التشغيل عند الإقلاع',
                      'سيُعيد الروت التفعيل تلقائياً بعد كل إقلاع للجهاز.\n'
                      'قد يستغرق بضع ثوانٍ بعد الإقلاع.',
                      'تفعيل',
                    );
                    if (!ok) return;
                  }
                  await settings.setExploitStartOnBoot(nv);
                },
              ),
            ),

            const Divider(height: 1),

            // إعادة تشغيل الواجهة تلقائياً
            ValueListenableBuilder<bool>(
              valueListenable: settings.exploitAutoSoftReboot,
              builder: (_, v, __) => SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('إعادة تشغيل الواجهة بعد الـ Exploit'),
                subtitle: const Text(
                    'يُعيد تشغيل واجهة Android تلقائياً بعد نجاح الـ Exploit'),
                value: v,
                onChanged: settings.setExploitAutoSoftReboot,
              ),
            ),
          ]),
        ),

        _tip('ℹ️ هذه الخيارات مطفأة بالافتراضي. فعّلها فقط إذا كنت تعرف ما تفعله.'),

        const SizedBox(height: 22),

        // ══════════════════════════════════════════════════════════════════
        // قسم إعدادات الروت العادي (الموديلات / soft reboot)
        // ══════════════════════════════════════════════════════════════════
        _sectionTitle(S.rootSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [

            ValueListenableBuilder<bool>(
              valueListenable: settings.autoSoftReboot,
              builder: (_, v, __) => SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(S.autoSoftReboot),
                subtitle: Text(S.autoSoftRebootSub),
                value: v,
                onChanged: settings.setAutoSoftReboot,
              ),
            ),

            const Divider(height: 1),

            ValueListenableBuilder<bool>(
              valueListenable: settings.disableModules,
              builder: (_, v, __) => SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(S.disableModules),
                subtitle: Text(S.disableModulesSub),
                value: v,
                onChanged: _busy ? null : _setAllModules,
              ),
            ),
          ]),
        ),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Text(S.bootLoopTip,
              style: const TextStyle(color: AppTheme.appWarning, height: 1.5)),
        ),

        const SizedBox(height: 22),

        // ══════════════════════════════════════════════════════════════════
        // قسم الخط
        // ══════════════════════════════════════════════════════════════════
        _sectionTitle(S.fontSection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined,
                  color: AppTheme.appPrimary),
              title: const Text('خط iPhone Emoji'),
              subtitle: Text(
                'iOS 26.4 / Unicode 17  |  '
                '${_root.fontInstalled ? S.fontAttached : S.fontNotAttached}\n'
                '${_root.customFont ? "ملف مستورد" : "الموديل المرفق"}',
              ),
              isThreeLine: true,
              trailing: _root.fontInstalled
                  ? TextButton(
                      onPressed: _busy ? null : _removeFont,
                      child: Text(S.removeModule,
                          style: const TextStyle(color: AppTheme.appError)),
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

        // ══════════════════════════════════════════════════════════════════
        // حول التطبيق
        // ══════════════════════════════════════════════════════════════════
        _sectionTitle(S.aboutSection),
        const AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(title: Text('الإصدار'), trailing: Text(S.appVersion)),
            Divider(height: 1),
            ListTile(
              title: Text('محرك الروت'),
              subtitle: Text('DFRoot / DirtyFrag (CVE-2026-43284)'),
            ),
            Divider(height: 1),
            ListTile(
              title: Text('مدير الوحدات'),
              subtitle: Text('KernelSU (samsung fork by diabl0w)'),
            ),
            Divider(height: 1),
            ListTile(
              title: Text('الاتصال بالإنترنت'),
              subtitle: Text('لا يوجد — التطبيق يعمل بالكامل دون إنترنت'),
            ),
          ]),
        ),

        if (_busy) const Center(child: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CircularProgressIndicator(),
        )),

        const SizedBox(height: 20),
      ]),
    );
  }
}
