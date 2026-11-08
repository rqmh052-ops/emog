import 'package:material_ui/material_ui.dart';
import 'app_settings.dart';
import 'log_output_widget.dart';
import 'log_screen.dart';
import 'page_transitions.dart';
import 'root_controller.dart';
import 'side_drawer.dart';
import 'soft_reboot.dart';
import 'status_card.dart';
import 'strings.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.startupError});
  final String? startupError;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _root = RootController.instance;
  late final AnimationController _intro;
  bool _flowActive = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    _root.addListener(_changed);
    _root.initialize();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _root.removeListener(_changed);
    _intro.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// بطاقة بحركة دخول متدرجة (تلاشي + انزلاق خفيف).
  Widget _enter(int index, Widget child) {
    final start = (index * 0.16).clamp(0.0, 0.7);
    final anim = CurvedAnimation(parent: _intro, curve: Interval(start, 1.0, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  Future<void> _showPermissions() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(S.permissions),
        content: const Text(
          'لا يحتاج التطبيق إلى أي صلاحيات: لا تخزين ولا إنترنت ولا تشغيل عند الإقلاع.\n\n'
          'صلاحية Root تُطلب فقط عند ضغط الزر، وتظهر نافذة الموافقة التابعة لمدير KernelSU أو APatch أو Magisk.\n\n'
          'لا يستطيع التطبيق إنشاء Root أو تفعيله إذا لم يكن موجوداً مسبقاً.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text(S.ok))],
      ),
    );
  }

  Future<void> _import() async {
    final message = await _root.importFont();
    if (message != null) _toast(message);
  }

  Future<bool> _confirmInstall() async {
    if (!_root.fontReady) {
      final goImport = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text(S.warning),
              content: const Text(S.noFont),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text(S.cancel)),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text(S.importFont)),
              ],
            ),
          ) ??
          false;
      if (goImport) await _import();
      return false;
    }
    final needMeta = _root.managerName == 'KernelSU' && !_root.hasMetamodule;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(S.warning),
            content: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(S.moduleScriptsWarning),
                if (needMeta) ...[
                  const SizedBox(height: 12),
                  const Text(S.metamoduleWarning,
                      style: TextStyle(color: AppTheme.appWarning, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text(S.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(_root.fontInstalled ? S.reinstall : S.install),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _launch() async {
    if (_root.busy || _flowActive) return;
    _flowActive = true;
    try {
      if (!_root.rootGranted) {
        final granted = await _root.requestRoot();
        if (!granted) {
          if (_root.errorMessage != null) _toast(_root.errorMessage!);
          return;
        }
        if (_root.fontInstalled) {
          _toast('صلاحية Root متاحة وموديل الخط مثبت بالفعل.');
          return;
        }
      }
      if (!mounted) return;
      if (!await _confirmInstall() || !mounted) return;
      final installed = await _root.installFont();
      if (!mounted) return;
      if (!installed) {
        if (_root.errorMessage != null) _toast(_root.errorMessage!);
        return;
      }
      if (AppSettings.instance.autoSoftReboot.value) {
        final ok = await SoftReboot.confirmAndRun(context);
        if (!ok) _toast('لم يتم تنفيذ إعادة تشغيل الواجهة.');
      }
    } finally {
      _flowActive = false;
    }
  }

  Future<void> _softReboot() async {
    final ok = await SoftReboot.confirmAndRun(context);
    if (!mounted) return;
    _toast(ok ? 'تم إرسال أمر إعادة تشغيل الواجهة' : 'لم يبدأ إعادة تشغيل الواجهة');
  }

  Future<void> _refresh() async {
    if (_root.busy) return;
    if (!_root.rootGranted) {
      await _root.requestRoot();
    } else {
      await _root.refreshModuleState();
    }
    await _root.refreshFontInfo();
  }

  String get _primaryLabel {
    if (!_root.rootGranted) return S.launch;
    return _root.fontInstalled ? S.reinstall : S.install;
  }

  @override
  Widget build(BuildContext context) {
    final fontDetails = <String>[
      'iOS 26.4  |  Unicode 17',
      'المصدر: ${_root.customFont ? 'ملف مستورد' : 'الموديل المرفق'}  |  حجم الخط: ${formatBytes(_root.fontBytes)}',
    ];
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(S.appName),
        actions: [
          IconButton(
            tooltip: S.aboutSection,
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: S.appName,
              applicationVersion: S.appVersion,
              children: const [Text(S.offlineNote)],
            ),
          ),
        ],
      ),
      drawer: SideDrawer(onPermissions: _showPermissions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
          children: [
            if (widget.startupError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.appError.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.appError.withValues(alpha: .35)),
                ),
                child: Text('تعذر تجهيز ملف الموديل: ${widget.startupError}',
                    style: const TextStyle(color: AppTheme.appError)),
              ),
              const SizedBox(height: 12),
            ],
            _enter(
              0,
              StatusCard(
                title: 'حالة Root',
                icon: Icons.admin_panel_settings_outlined,
                status: _root.rootGranted
                    ? S.rootActive
                    : (_root.status == S.rootUnknown ? S.rootUnknown : S.rootInactive),
                active: _root.rootGranted,
                details: [
                  'المصنّع: ${_root.manufacturer}',
                  'الجهاز: ${_root.model}',
                  'Android: ${_root.androidVersion}  |  Kernel: ${_root.kernelVersion}',
                  'المدير: ${_root.managerName}',
                ],
              ),
            ),
            const SizedBox(height: 12),
            _enter(
              1,
              StatusCard(
                title: S.fontTitle,
                icon: Icons.emoji_emotions_outlined,
                status: _root.fontInstalled ? S.fontInstalled : S.fontNotInstalled,
                active: _root.fontInstalled,
                details: fontDetails,
                trailing: _root.fontReady
                    ? null
                    : const Text(
                        'ملف الخط فارغ: استورد ملف ‎.ttf‎ أو موديلاً جاهزاً قبل التثبيت.',
                        style: TextStyle(color: AppTheme.appWarning, fontSize: 13, height: 1.4),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            _enter(
              2,
              _root.busy
                  ? Column(children: [
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(color: AppTheme.appPrimary),
                      ),
                      Text(_root.status,
                          style: const TextStyle(color: AppTheme.appMuted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                    ])
                  : SizedBox(
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: _launch,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(_primaryLabel,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
            ),
            if (_root.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_root.errorMessage!, style: const TextStyle(color: AppTheme.appError)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _root.busy ? null : _import,
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text(S.importFont),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _root.busy ? null : _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(S.refresh),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(SmoothPageRoute<void>(builder: (_) => const LogScreen())),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text(S.viewLogs),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _root.rootGranted ? _softReboot : null,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text(S.softReboot),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            const Text('السجل المباشر', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            LogOutputWidget(lines: _root.logs),
            const SizedBox(height: 14),
            const AppCard(
              padding: EdgeInsets.all(12),
              child: Text(S.rootNote, style: TextStyle(color: AppTheme.appMuted, fontSize: 12.5, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
