import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'strings.dart';
import 'theme.dart';

/// ينسخ كل أسطر السجل إلى الحافظة ويعرض رسالة تأكيد (مشتركة بين الرئيسية وشاشة السجل).
Future<void> copyLogs(BuildContext context, List<String> logs) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: logs.join('\n')));
  messenger.showSnackBar(SnackBar(content: Text(S.logCopied)));
}

Color logColor(String line) {
  if (line.contains('✅')) return AppTheme.appSuccess;
  if (line.contains('❌')) return AppTheme.appError;
  if (line.contains('⚠️')) return AppTheme.appWarning;
  if (line.contains('⏳') || line.contains('🔍') || line.contains('📦') || line.contains('ℹ️')) {
    return AppTheme.appCyan;
  }
  return AppTheme.appText;
}

class LogOutputWidget extends StatelessWidget {
  const LogOutputWidget({super.key, required this.lines, this.maxHeight = 200});
  final List<String> lines;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final visible = lines.length > 10 ? lines.sublist(lines.length - 10) : lines;
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: AppTheme.appConsole,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.appBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: visible.isEmpty
          ? Center(child: Text(S.noLogs, style: const TextStyle(color: AppTheme.appDim)))
          : ListView.builder(
              reverse: true,
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final line = visible[visible.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    line,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.4, color: logColor(line)),
                  ),
                );
              },
            ),
    );
  }
}
