import 'package:material_ui/material_ui.dart';
import 'theme.dart';

/// بطاقة بسيطة (بدون الاعتماد على Card كي لا تتأثر بتغيّر واجهات الثيم).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.appSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.appBorder),
      ),
      child: child,
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.active,
    this.details = const [],
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String status;
  final bool active;
  final List<String> details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.appSuccess : AppTheme.appMuted;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.appPrimary, size: 21),
            const SizedBox(width: 9),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.map((line) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(line, style: const TextStyle(color: AppTheme.appMuted, fontSize: 13.5)),
                )),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
