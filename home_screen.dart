import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'app_dialogs.dart';
import 'app_settings.dart';
import 'log_output_widget.dart';
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
  /// الفحص التلقائي يتم مرة واحدة فقط عند فتح التطبيق.
  static bool _startupChecked = false;

  final _root = RootController.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _intro;
  bool _flowActive = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    _root.addListener(_changed);
    final init = _root.initialize();
    if (!_startupChecked) {
      _startupChecked = true;
      _starting = true;
      unawaited(_startup(init));
    }
  }

  Future<void> _startup(Future<void> init) async {
    try {
      await init;
      if (await _root.requestRoot()) await _root.refreshModuleState();
      await _root.refreshFontInfo();
    } catch (_) {
      // تبقى الحالة «لا توجد صلاحية» ويمكن الضغط على الزر لإعادة المحاولة.
    } finally {
      if (mounted) setState(() => _starting = false);
    }
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

  bool get _checking => _starting || _root.checkingRoot;

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

  Future<void> _attach() async {
    final message = await _root.importFont();
    if (message != null) _toast(message);
  }

  Future<bool> _confirmInstall() async {
    if (!_root.fontReady) {
      _toast(S.attachFontFirst);
      return false;
    }
    final needMeta = _root.managerName == 'KernelSU' && !_root.hasMetamodule;
    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  '),
            Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
          ]),
        );
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.important),
            content: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                bullet(S.warnLine1),
                bullet(S.warnLine2),
                bullet(S.warnLine3),
                const SizedBox(height: 6),
                Text(S.continueOnlyIfAgree, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (needMeta) ...[
                  const SizedBox(height: 12),
                  Text(S.metamoduleWarning,
                      style: const TextStyle(color: AppTheme.appWarning, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(S.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(_root.fontInstalled ? S.reinstall : S.install),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// كل ضغطة تنفّذ خطوة واحدة فقط: طلب الروت، أو إرفاق الخط، أو التثبيت.
  Future<void> _primary() async {
    if (_root.busy || _flowActive || _checking) return;
    _flowActive = true;
    try {
      if (!_root.rootGranted) {
        final granted = await _root.requestRoot();
        if (!granted && _root.errorMessage != null) _toast(_root.errorMessage!);
        return;
      }
      if (!_root.fontReady) {
        await _attach();
        return;
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
        if (!ok) _toast(S.softRebootNotDone);
      }
    } finally {
      _flowActive = false;
    }
  }

  Future<void> _softReboot() async {
    final ok = await SoftReboot.confirmAndRun(context);
    if (!mounted) return;
    _toast(ok ? S.softRebootSent : S.softRebootNotStarted);
  }

  String get _primaryLabel {
    if (!_root.rootGranted) return S.requestRoot;
    if (!_root.fontReady) return S.attachFont;
    return _root.fontInstalled ? S.reinstall : S.install;
  }

  IconData get _primaryIcon {
    if (!_root.rootGranted) return Icons.lock_open_rounded;
    if (!_root.fontReady) return Icons.attach_file_rounded;
    return Icons.download_rounded;
  }

  /// النواة: الرقم الأول فقط (ما قبل أول «-»).
  String get _kernelShort {
    final v = _root.kernelVersion.trim();
    if (v.isEmpty || v == '—') return '—';
    final short = v.split('-').first.trim();
    return short.isEmpty ? '—' : short;
  }

  Widget _info(String title, String value) => Expanded(
        child: Column(children: [
          Text(title, style: const TextStyle(color: AppTheme.appMuted, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _statusCard() {
    final Color color;
    final String text;
    if (_checking) {
      color = AppTheme.appCyan;
      text = S.rootChecking;
    } else if (_root.rootGranted) {
      color = AppTheme.appSuccess;
      text = '✓  ${S.rootVerified}';
    } else {
      color = AppTheme.appError;
      text = S.rootMissing;
    }
    return AppCard(
      child: Column(children: [
        const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.appPrimary, size: 34),
        const SizedBox(height: 8),
        Text(S.rootStatus, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _info(S.manufacturer, _root.manufacturer),
          _info(S.android, _root.androidVersion),
          _info(S.kernel, _kernelShort),
        ]),
      ]),
    );
  }

  Widget _primaryArea() {
    if (_checking || _root.busy) {
      return Column(children: [
        const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: AppTheme.appPrimary)),
        Text(_checking ? S.rootChecking : _root.status,
            style: const TextStyle(color: AppTheme.appMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
      ]);
    }
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: _primary,
        icon: Icon(_primaryIcon),
        label: Text(_primaryLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final menuButton = IconButton(
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => rtl ? _scaffoldKey.currentState?.openEndDrawer() : _scaffoldKey.currentState?.openDrawer(),
    );
    final drawer = SideDrawer(
      onPhoneInfo: () => AppDialogs.phoneInfo(context),
      onPermissions: () => AppDialogs.permissions(context),
      onOpenSources: () => AppDialogs.openSources(context),
    );
    final logs = _root.logs;
    // القائمة وزرها على يسار الشاشة الفعلي في اللغتين:
    // RTL: endDrawer والزر في actions. LTR: drawer والزر في leading.
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: rtl ? null : menuButton,
        title: Text(S.appName),
        actions: rtl ? [menuButton] : null,
      ),
      drawer: rtl ? null : drawer,
      endDrawer: rtl ? drawer : null,
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
                child: Text(S.startupError(widget.startupError!), style: const TextStyle(color: AppTheme.appError)),
              ),
              const SizedBox(height: 12),
            ],
            _enter(0, _statusCard()),
            const SizedBox(height: 14),
            _enter(1, _primaryArea()),
            if (_root.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_root.errorMessage!, style: const TextStyle(color: AppTheme.appError)),
            ],
            if (_root.rootGranted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _softReboot,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(S.softReboot),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text(S.liveLog, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              IconButton(
                tooltip: S.copy,
                onPressed: logs.isEmpty ? null : () => copyLogs(context, logs),
                icon: const Icon(Icons.copy_rounded, size: 20),
              ),
            ]),
            const SizedBox(height: 4),
            LogOutputWidget(lines: logs),
          ],
        ),
      ),
    );
  }
}
