import 'package:material_ui/material_ui.dart';
import 'ksu_manager.dart';
import 'strings.dart';

class SoftReboot {
  static Future<bool> confirmAndRun(BuildContext context) async {
    final approved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.softReboot),
            content: Text(S.softRebootBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(S.cancel)),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(S.confirm)),
            ],
          ),
        ) ??
        false;
    if (!approved) return false;
    final result = await KsuManager.instance.softReboot();
    return result['success'] == true;
  }
}
