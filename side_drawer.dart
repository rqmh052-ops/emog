import 'dart:convert';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_settings.dart';
import 'log_screen.dart';
import 'logo.dart';
import 'page_transitions.dart';
import 'root_controller.dart';
import 'settings_screen.dart';
import 'strings.dart';
import 'theme.dart';

final Uint8List _bynuxLogo = base64Decode(kAppLogoBase64);
final Uint8List _bayanLogo = base64Decode(kLogoBase64);
final Uint8List _flagAr = base64Decode(kFlagArBase64);
final Uint8List _flagEn = base64Decode(kFlagEnBase64);

BoxDecoration _box(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.appBorderHigh),
    );

Future<void> _open(String value) async {
  try {
    await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// تأثير ضغط خفيف (تصغير) كما في قائمة بيان.
class _PressFx extends StatefulWidget {
  const _PressFx({required this.child});
  final Widget child;
  @override
  State<_PressFx> createState() => _PressFxState();
}

class _PressFxState extends State<_PressFx> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// زر بحد بلون أساسي (نفس زر بيان).
class _OButton extends StatelessWidget {
  const _OButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _PressFx(
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.appPrimary,
              backgroundColor: AppTheme.appPrimary.withValues(alpha: .08),
              side: const BorderSide(color: AppTheme.appPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      );
}

class SideDrawer extends StatelessWidget {
  const SideDrawer({
    super.key,
    required this.onPhoneInfo,
    required this.onPermissions,
    required this.onOpenSources,
  });
  final VoidCallback onPhoneInfo, onPermissions, onOpenSources;

  Widget _nav(IconData icon, String label, bool active, VoidCallback action) {
    return Material(
      color: active ? AppTheme.appPrimary.withValues(alpha: .14) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(icon, color: active ? AppTheme.appPrimary : AppTheme.appMuted, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: active ? AppTheme.appPrimary : AppTheme.appText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _link(IconData icon, String label, String url) =>
      Expanded(child: _OButton(label: label, icon: icon, onPressed: () => _open(url)));

  // صف واحد في لوحة اللغة: العلم الدائري ثم فاصل عمودي ثم اسم اللغة.
  Widget _langRow(BuildContext context, {
    required String code,
    required Uint8List flagBytes,
    required String label,
    required bool selected,
  }) {
    const accent = AppTheme.appPrimary;
    return Material(
      color: selected ? accent.withValues(alpha: .15) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (S.englishIsLtr) Navigator.pop(context);
          AppSettings.instance.setLanguage(code);
        },
        child: SizedBox(
          height: 44,
          child: Row(children: [
            SizedBox(
              width: 54,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? accent : AppTheme.appBorderHigh,
                      width: selected ? 1.8 : 1.0,
                    ),
                    boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 8)] : null,
                  ),
                  child: ClipOval(
                    child: Image.memory(flagBytes, width: 28, height: 28, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 44, color: selected ? accent.withValues(alpha: .35) : AppTheme.appBorder),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: selected ? accent : AppTheme.appText,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  )),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.check_circle_rounded, color: accent, size: 18),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _languagePanel(BuildContext context) {
    final current = AppSettings.instance.language.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          const Icon(Icons.language_outlined, color: AppTheme.appMuted, size: 20),
          const SizedBox(width: 12),
          Text(S.language,
              style: const TextStyle(color: AppTheme.appText, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
      Container(
        decoration: _box(AppTheme.appBackground),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _langRow(context, code: 'ar', flagBytes: _flagAr, label: S.langArabic, selected: current != 'en'),
          Container(height: 1, color: AppTheme.appBorder),
          _langRow(context, code: 'en', flagBytes: _flagEn, label: S.langEnglish, selected: current == 'en'),
        ]),
      ),
    ]);
  }

  Widget _channelCard({
    required Uint8List logo,
    required String title,
    required String subtitle,
    required List<Widget> buttons,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(AppTheme.appBackground),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ClipOval(child: Image.memory(logo, width: 52, height: 52, fit: BoxFit.cover, gaplessPlayback: true)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.appMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: buttons),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Drawer(
        width: 300,
        backgroundColor: AppTheme.appSurface,
        shape: const RoundedRectangleBorder(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(S.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${S.version} ${S.appVersion}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.appMuted)),
                  ]),
                ),
                _nav(Icons.home_outlined, S.home, true, () => Navigator.pop(context)),
                const SizedBox(height: 4),
                _nav(Icons.settings_outlined, S.settings, false, () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav
                      .push(SmoothPageRoute<void>(builder: (_) => const SettingsScreen()))
                      .then((_) => RootController.instance.refreshFontInfo());
                }),
                const SizedBox(height: 4),
                _nav(Icons.receipt_long_outlined, S.logs, false, () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(SmoothPageRoute<void>(builder: (_) => const LogScreen()));
                }),
                const SizedBox(height: 4),
                _nav(Icons.phone_android_outlined, S.phoneInfo, false, () {
                  Navigator.pop(context);
                  onPhoneInfo();
                }),
                const SizedBox(height: 4),
                _nav(Icons.verified_user_outlined, S.permissionsCheck, false, () {
                  Navigator.pop(context);
                  onPermissions();
                }),
                const SizedBox(height: 6),
                _languagePanel(context),
                const SizedBox(height: 20),
                _channelCard(
                  logo: _bynuxLogo,
                  title: S.bynuxName,
                  subtitle: S.updatesChannel,
                  buttons: [_link(Icons.send_outlined, S.telegram, S.bynuxUrl)],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                  child: Text(S.aboutApp, style: const TextStyle(fontSize: 13, color: AppTheme.appMuted)),
                ),
                _channelCard(
                  logo: _bayanLogo,
                  title: S.bayanName,
                  subtitle: S.bayanTagline,
                  buttons: [
                    _link(Icons.smart_display_outlined, S.youtube, S.youtubeUrl),
                    const SizedBox(width: 8),
                    _link(Icons.send_outlined, S.telegram, S.bayanUrl),
                  ],
                ),
                const SizedBox(height: 20),
                _nav(Icons.info_outline, S.openSources, false, () {
                  Navigator.pop(context);
                  onOpenSources();
                }),
              ]),
            ),
          ),
        ),
      );
}
