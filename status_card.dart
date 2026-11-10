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
