import 'package:material_ui/material_ui.dart';
import 'ksu_manager.dart';
import 'strings.dart';

class SoftReboot {
  static Future<bool> confirmAndRun(BuildContext context) async {
    final approved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(S.softReboot),
            content: const Text(
              'سيتم إغلاق واجهة Android وإعادة تشغيلها.\nهذا ليس إعادة تشغيل كاملة للهاتف.\nقد تتوقف التطبيقات المفتوحة مؤقتاً.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text(S.cancel)),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text(S.confirm)),
            ],
          ),
        ) ??
        false;
    if (!approved) return false;
    final result = await KsuManager.instance.softReboot();
    return result['success'] == true;
  }
}
