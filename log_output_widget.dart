import 'package:material_ui/material_ui.dart';
import 'theme.dart';

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
          ? const Center(child: Text('لا توجد رسائل بعد', style: TextStyle(color: AppTheme.appDim)))
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
