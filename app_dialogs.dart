import 'package:material_ui/material_ui.dart';
import 'root_controller.dart';
import 'strings.dart';
import 'theme.dart';

/// نوافذ القائمة الجانبية: فحص الصلاحيات، طراز الهاتف، المصادر المفتوحة.
class AppDialogs {
  static Future<void> permissions(BuildContext context) {
    final root = RootController.instance;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: root,
        builder: (context, _) {
          final ok = root.rootGranted;
          final color = ok ? AppTheme.appSuccess : AppTheme.appError;
          return AlertDialog(
            title: Text(S.permissionsCheck),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(S.rootPermission, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(ok ? S.available : S.notAvailable,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                Text(S.noOtherPermissions, style: const TextStyle(color: AppTheme.appMuted)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: root.busy ? null : () => root.requestRoot(),
                child: Text(S.checkAgain),
              ),
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(S.ok)),
            ],
          );
        },
      ),
    );
  }

  static Future<void> phoneInfo(BuildContext context) {
    final root = RootController.instance;
    final rows = <MapEntry<String, String>>[
      MapEntry(S.manufacturer, root.manufacturer),
      MapEntry(S.model, root.model),
      MapEntry(S.android, root.androidVersion),
      MapEntry(S.kernel, root.kernelVersion),
      MapEntry(S.rootManager, root.managerLabel),
    ];
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.phoneInfo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectableText.rich(TextSpan(children: [
                    TextSpan(
                      text: '${row.key}: ',
                      style: const TextStyle(color: AppTheme.appMuted, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: row.value),
                  ])),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(S.ok))],
      ),
    );
  }

  static Future<void> openSources(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.openSources),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.openSourcesRoot, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 8),
            Text(S.openSourcesFont, style: const TextStyle(height: 1.5)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(S.ok))],
      ),
    );
  }
}
