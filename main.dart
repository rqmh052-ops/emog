import 'package:material_ui/material_ui.dart';
import 'app.dart';
import 'app_settings.dart';
import 'asset_extractor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.initialize();
  try {
    await AssetExtractor.instance.prepare();
  } catch (_) {
    // يبقى التطبيق قابلاً للاستخدام؛ يعاد التجهيز عند التثبيت ويظهر الخطأ.
  }
  runApp(EmojiRootApp(startupError: AssetExtractor.instance.lastError));
}
