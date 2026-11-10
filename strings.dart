import 'app_settings.dart';

/// نصوص التطبيق. كل نص دالة تقرأ اللغة الحالية.
/// الإنجليزية وهمية حالياً (تعرض العربية). لإضافتها لاحقاً مرّر النص الإنجليزي
/// كوسيط ثانٍ لـ _t، مثل: _t('الرئيسية', 'Home').
class S {
  static String _t(String ar, [String? en]) =>
      AppSettings.instance.language.value == 'en' ? (en ?? ar) : ar;

  /// عند true: يتحول الاتجاه إلى LTR في الوضع الإنجليزي.
  /// اجعلها false لإبقاء الاتجاه RTL إلى أن تُضاف الترجمة الإنجليزية.
  static const bool englishIsLtr = true;

  static const appVersion = '2.1.0';
  static const bynuxName = 'Bynux';
  static const langArabic = 'العربية';
  static const langEnglish = 'English';
  static const bynuxUrl = 'https://t.me/Bynux_777';
  static const bayanUrl = 'https://t.me/Bayan_x777';
  static const youtubeUrl = 'https://youtube.com/channel/UC4Ox1C-_DWCbIeiWJ_6rV9Q';

  static String get appName => _t('روت الإيموجي');
  static String get version => _t('الإصدار');
  static String get home => _t('الرئيسية');
  static String get settings => _t('الإعدادات');
  static String get logs => _t('السجل');
  static String get phoneInfo => _t('طراز الهاتف');
  static String get permissionsCheck => _t('فحص الصلاحيات');
  static String get language => _t('اللغة');
  static String get updatesChannel => _t('قناة التحديثات');
  static String get telegram => _t('تليجرام');
  static String get youtube => _t('يوتيوب');
  static String get aboutApp => _t('حول التطبيق');
  static String get bayanName => _t('بيان');
  static String get bayanTagline => _t('شروحات تقنية مبسطة');
  static String get openSources => _t('المصادر المفتوحة');
  static String get openSourcesRoot => _t('مدير الروت: KernelSU (github.com/tiann/KernelSU) أو Magisk أو APatch.');
  static String get openSourcesFont => _t('موديل الخط: iOS 26.4 / Unicode 17 (zFont)، وسكربتاته مبنية على killgmsfont.');

  static String get rootStatus => _t('حالة الروت');
  static String get rootChecking => _t('جارٍ التحقق من الروت…');
  static String get rootVerified => _t('تم التحقق من صلاحية الروت');
  static String get rootMissing => _t('لا توجد صلاحية روت بعد');
  static String get manufacturer => _t('المصنّع');
  static String get android => _t('أندرويد');
  static String get kernel => _t('النواة');
  static String get model => _t('الطراز');
  static String get rootManager => _t('مدير الروت');
  static String get unknown => _t('غير معروف');

  static String get requestRoot => _t('طلب صلاحية الروت');
  static String get attachFont => _t('إرفاق ملف الخط');
  static String get changeFont => _t('تغيير الخط');
  static String get removeFont => _t('حذف الخط المرفق');
  static String get install => _t('تثبيت الموديل');
  static String get reinstall => _t('إعادة تثبيت الموديل');
  static String get removeModule => _t('إزالة الموديل');
  static String get softReboot => _t('إعادة تشغيل الواجهة');
  static String get liveLog => _t('السجل المباشر');
  static String get noLogs => _t('لا توجد رسائل بعد');
  static String get noLogsYet => _t('لا يوجد سجل حتى الآن');
  static String get copy => _t('نسخ');
  static String get logCopied => _t('تم نسخ السجل');
  static String get clear => _t('مسح');
  static String get attachFontFirst => _t('أرفق ملف الخط أولاً');
  static String get cancel => _t('إلغاء');
  static String get confirm => _t('تأكيد');
  static String get ok => _t('حسناً');
  static String get delete => _t('حذف');
  static String get disable => _t('تعطيل');
  static String get enable => _t('تفعيل');
  static String get checkAgain => _t('إعادة الفحص');

  static String get important => _t('تنبيه مهم');
  static String get warningTitle => _t('تحذير');
  static String get warnLine1 => _t('يعطّل مكوّنين من خطوط Google Play Services.');
  static String get warnLine2 => _t('يحذف مجلد /data/fonts ويستبدل ملفات الإيموجي داخل فيسبوك وماسنجر وGboard.');
  static String get warnLine3 => _t('يعطّل موديلات الخطوط المتعارضة.');
  static String get continueOnlyIfAgree => _t('لا تكمل إلا إذا وافقت.');
  static String get metamoduleWarning =>
      _t('لم يتم العثور على Metamodule. ثبّت واحداً متوافقاً (مثل meta-overlayfs) ثم أعد التشغيل، وإلا لن يتغير الخط.');
  static String get bootLoopTip =>
      _t('إذا علق الجهاز عند الإقلاع: أطفئه ثم ادخل الوضع الآمن بأزرار الصوت (يعطّل الموديلات تلقائياً في KernelSU وMagisk).');
  static String get noRoot => _t('لا توجد صلاحية روت. فعّل الروت من خارج التطبيق ثم أعد المحاولة.');

  static String get rootPermission => _t('صلاحية الروت');
  static String get available => _t('متاحة');
  static String get notAvailable => _t('غير متاحة');
  static String get noOtherPermissions => _t('لا يحتاج التطبيق أي صلاحية أخرى');

  static String get rootSection => _t('إعدادات الروت');
  static String get fontSection => _t('الخط');
  static String get fontAttached => _t('مرفق');
  static String get fontNotAttached => _t('غير مرفق');
  static String get autoSoftReboot => _t('اقتراح إعادة تشغيل الواجهة بعد التثبيت');
  static String get autoSoftRebootSub => _t('يعرض سؤال تأكيد بعد التثبيت، ولا يعيد التشغيل تلقائياً');
  static String get disableModules => _t('تعطيل جميع الموديلات');
  static String get disableModulesSub => _t('خيار طوارئ عند حدوث مشكلة في الإقلاع');
  static String get disableAllBody =>
      _t('سيتم تعطيل جميع موديلات مدير الروت، بما فيها موديل الإيموجي. استخدم هذا الخيار للطوارئ فقط.');
  static String get enableAllBody =>
      _t('سيتم إعادة تفعيل جميع الموديلات. قد تعود المشكلة التي سببت حلقة الإقلاع.');
  static String get modulesDisabledLog => _t('⚠️ تم تعطيل جميع الموديلات (أعد التشغيل)');
  static String get modulesEnabledLog => _t('✅ تم إعادة تفعيل الموديلات (أعد التشغيل)');
  static String get opFailedLog => _t('تعذر تنفيذ العملية');
  static String get commandDone => _t('تم تنفيذ الأمر');
  static String get operationFailed => _t('فشلت العملية');
  static String get removeModuleTitle => _t('إزالة الموديل');
  static String get removeModuleBody =>
      _t('سيتم إرسال أمر إزالة الموديل إلى مدير الروت. أعد تشغيل الجهاز لإزالة كل آثاره.');
  static String get removeRequestSent => _t('تم إرسال طلب الإزالة');
  static String get removeFailed => _t('فشلت الإزالة');
  static String get removeFontTitle => _t('حذف الخط المرفق');
  static String get removeFontBody => _t('سيتم حذف الخط المرفق من التطبيق. الموديل المثبّت في الجهاز لا يتأثر.');
  static String get fontRemoved => _t('تم حذف الخط المرفق');

  static String get softRebootBody =>
      _t('سيتم إغلاق واجهة أندرويد وإعادة تشغيلها.\nهذا ليس إعادة تشغيل كاملة للهاتف.\nقد تتوقف التطبيقات المفتوحة مؤقتاً.');
  static String get softRebootNotDone => _t('لم يتم تنفيذ إعادة تشغيل الواجهة.');
  static String get softRebootSent => _t('تم إرسال أمر إعادة تشغيل الواجهة');
  static String get softRebootNotStarted => _t('لم يبدأ إعادة تشغيل الواجهة');

  static String startupError(String e) => _t('تعذر تجهيز الموديل: $e');
  static String get importedReinstall => _t('تم الاستيراد. أعد تثبيت الموديل');
  static String get fontAttachedToast => _t('تم إرفاق الخط');

  // نصوص يولّدها المتحكم في السجل والحالة
  static String get logCheckingRoot => _t('🔍 جارٍ التحقق من صلاحية الروت');
  static String get statusRequestFailed => _t('تعذر طلب الروت');
  static String logRootFailed(String e) => _t('❌ فشل طلب الروت: $e');
  static String logRootGranted(String m) => _t('✅ تم منح التطبيق صلاحية الروت ($m)');
  static String get logModuleInstalled => _t('✅ الموديل مثبت');
  static String get logModuleNotInstalled => _t('ℹ️ الموديل غير مثبت');
  static String get logNoMetamodule => _t('⚠️ لا يوجد Metamodule في KernelSU؛ لن يُركّب مجلد system');
  static String get statusInstalling => _t('جارٍ تثبيت الموديل…');
  static String get logPreparing => _t('📦 جارٍ تجهيز الموديل');
  static String get statusInstallFailed => _t('فشل تثبيت الموديل');
  static String get installFailedMsg => _t('تعذر تثبيت الموديل. تحقق من صلاحية الروت ومدير الوحدات.');
  static String get logInstallFailed => _t('❌ فشل تثبيت الموديل');
  static String get statusInstalled => _t('تم تثبيت الموديل');
  static String get logInstalled => _t('✅ تم تثبيت الموديل عبر مدير الروت');
  static String get logRestartHint => _t('ℹ️ أعد تشغيل الواجهة أو الجهاز لتطبيق التغييرات');
  static String logInstallError(String e) => _t('❌ خطأ أثناء تثبيت الموديل: $e');
  static String get removeFailedMsg => _t('تعذرت إزالة الموديل');
  static String get logRemoveSent => _t('✅ تم إرسال طلب إزالة الموديل (يكتمل بعد إعادة التشغيل)');
  static String get logRemoveFailed => _t('❌ فشلت إزالة الموديل');
  static String logRemoveError(String e) => _t('❌ خطأ أثناء إزالة الموديل: $e');
  static String logImporting(String n) => _t('📦 جارٍ استيراد: $n');
  static String get importFailed => _t('فشل الاستيراد');
  static String logImported(String size) => _t('✅ تم استيراد الخط ($size)');
  static String importFailedWith(String e) => _t('فشل الاستيراد: $e');
  static String logImportFailedWith(String e) => _t('❌ فشل الاستيراد: $e');
  static String get logFontRemoved => _t('ℹ️ تم حذف الخط المرفق');
  static String get logDeviceLoaded => _t('✅ تم تحميل معلومات الجهاز');
  static String logManager(String m) => _t('ℹ️ مدير الروت المحتمل: $m');
  static String logDeviceFailed(String e) => _t('⚠️ تعذر قراءة بعض معلومات الجهاز: $e');

  static String get unitByte => _t('بايت');
  static String get unitKB => _t('ك.ب');
  static String get unitMB => _t('م.ب');
}
