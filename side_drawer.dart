import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'log_screen.dart';
import 'page_transitions.dart';
import 'settings_screen.dart';
import 'strings.dart';
import 'theme.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key, required this.onPermissions});
  final VoidCallback onPermissions;

  static const _bynux = 'https://t.me/Bynux_777';
  static const _bayan = 'https://t.me/Bayan_x777';

  Future<void> _open(String value) async {
    try {
      await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

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

  Widget _channel(IconData icon, String label, String url) {
    return OutlinedButton.icon(
      onPressed: () => _open(url),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF244C91), AppTheme.appSurface],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.appBorderHigh),
                  ),
                  child: const Row(children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0x334D8BFF),
                      child: Icon(Icons.emoji_emotions_outlined, color: AppTheme.appText, size: 27),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(S.appName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('الإصدار ${S.appVersion}', style: TextStyle(fontSize: 12, color: AppTheme.appMuted)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _nav(Icons.home_outlined, S.home, true, () => Navigator.pop(context)),
                const SizedBox(height: 4),
                _nav(Icons.settings_outlined, S.settings, false, () {
                  Navigator.pop(context);
                  Navigator.of(context).push(SmoothPageRoute<void>(builder: (_) => const SettingsScreen()));
                }),
                const SizedBox(height: 4),
                _nav(Icons.receipt_long_outlined, S.logs, false, () {
                  Navigator.pop(context);
                  Navigator.of(context).push(SmoothPageRoute<void>(builder: (_) => const LogScreen()));
                }),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _nav(Icons.admin_panel_settings_outlined, S.permissions, false, () {
                  Navigator.pop(context);
                  onPermissions();
                }),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text('قنوات Telegram',
                      style: TextStyle(color: AppTheme.appMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                _channel(Icons.send_rounded, 'قناة بينكس', _bynux),
                const SizedBox(height: 8),
                _channel(Icons.campaign_outlined, 'قناة بيان', _bayan),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _nav(Icons.info_outline, S.openSource, false, () {
                  showAboutDialog(
                    context: context,
                    applicationName: S.appName,
                    applicationVersion: S.appVersion,
                    children: const [
                      Text('إدارة موديل الخط تعتمد على مدير Root الموجود مسبقاً مثل KernelSU أو Magisk أو APatch.'),
                      SizedBox(height: 8),
                      Text('مصدر KernelSU: github.com/tiann/KernelSU'),
                      Text('موديل الخط: iOS 26.4 / Unicode 17 (zFont)، وسكربتاته مبنية على killgmsfont.'),
                      Text('لا يتضمن هذا التطبيق أي أداة تفعيل Root أو استغلال ثغرات.'),
                    ],
                  );
                }),
              ]),
            ),
          ),
        ),
      );
}
