import 'package:material_ui/material_ui.dart';
import 'home_screen.dart';
import 'strings.dart';
import 'theme.dart';

class EmojiRootApp extends StatelessWidget {
  const EmojiRootApp({super.key, this.startupError});
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: HomeScreen(startupError: startupError),
    );
  }
}
