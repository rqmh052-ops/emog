import 'package:material_ui/material_ui.dart';
import 'app_settings.dart';
import 'home_screen.dart';
import 'strings.dart';
import 'theme.dart';

class EmojiRootApp extends StatelessWidget {
  const EmojiRootApp({super.key, this.startupError});
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.instance.language,
      builder: (context, lang, _) => MaterialApp(
        title: S.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) => Directionality(
          textDirection: (lang == 'en' && S.englishIsLtr) ? TextDirection.ltr : TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: HomeScreen(startupError: startupError),
      ),
    );
  }
}
