class S {
  static const appName = 'روت الإيموجي';
  static const appVersion = '2.0.0';
  static const home = 'الرئيسية';
  static const settings = 'الإعدادات';
  static const logs = 'السجل';
  static const permissions = 'الصلاحيات';
  static const openSource = 'المصادر المفتوحة';
  static const launch = 'طلب صلاحية Root';
  static const rootActive = 'صلاحية Root متاحة';
  static const rootInactive = 'لم تُمنح صلاحية Root';
  static const rootUnknown = 'لم يتم التحقق من Root بعد';
  static const fontTitle = 'خط iPhone Emoji';
  static const fontInstalled = 'الموديل مثبت';
  static const fontNotInstalled = 'الموديل غير مثبت';
  static const viewLogs = 'عرض السجل';
  static const softReboot = 'إعادة تشغيل الواجهة';
  static const copy = 'نسخ';
  static const clear = 'مسح';
  static const cancel = 'إلغاء';
  static const confirm = 'تأكيد';
  static const ok = 'حسناً';
  static const warning = 'تنبيه مهم';
  static const install = 'تثبيت الموديل';
  static const reinstall = 'إعادة تثبيت الموديل';
  static const remove = 'إزالة';
  static const importFont = 'استيراد خط / موديل';
  static const refresh = 'فحص الحالة';
  static const rootSection = 'إعدادات Root';
  static const fontSection = 'الخط';
  static const aboutSection = 'حول التطبيق';
  static const autoSoftReboot = 'اقتراح إعادة تشغيل الواجهة بعد التثبيت';
  static const autoSoftRebootSubtitle = 'يعرض سؤال تأكيد بعد تثبيت الموديل، ولا يعيد التشغيل تلقائياً';
  static const disableModules = 'تعطيل جميع الموديلات';
  static const disableModulesSubtitle = 'خيار طوارئ عند حدوث مشكلة في الإقلاع';
  static const bootLoopTip =
      'في حالة حلقة الإقلاع: أوقف الجهاز، ثم ادخل الوضع الآمن باستخدام أزرار الصوت حسب نوع جهازك (يعطّل الموديلات تلقائياً في KernelSU وMagisk).';
  static const noRoot = 'لم يتم العثور على صلاحية Root. فعّل الروت من خارج التطبيق ثم أعد المحاولة.';
  static const noFont =
      'ملف الخط داخل الموديل المرفق فارغ (0 بايت)، وتثبيته سيُفسد عرض الإيموجي.\n\nاستورد ملف الخط الحقيقي (‎.ttf‎) أو موديلاً جاهزاً (‎.zip‎) بنفس المعرّف iOS26.4Unicode17 ثم أعد المحاولة.';
  static const metamoduleWarning =
      'لم يتم العثور على Metamodule في KernelSU. قد يُثبّت الموديل بنجاح، لكن مجلد system لن يُركّب ولن يتغير الخط حتى تثبّت Metamodule متوافقاً مثل meta-overlayfs أو meta-magicmount ثم تعيد التشغيل.';
  static const moduleScriptsWarning =
      'الموديل يحتوي سكربتات تعمل بصلاحيات Root: تعطّل مكوّنين من خطوط Google Play Services، وتحذف مجلد /data/fonts، وتبحث عن ملفات Emoji داخل بيانات بعض التطبيقات (فيسبوك وماسنجر وGboard) وتستبدلها، وتعطّل موديلات الخطوط المتعارضة. لا تثبّته إلا إذا وافقت على ذلك.';
  static const offlineNote =
      'التطبيق يعمل بالكامل دون إنترنت: لا حسابات ولا خدمات سحابية ولا صلاحية INTERNET. روابط القنوات تُفتح خارج التطبيق عند الضغط عليها.';
  static const rootNote =
      'مهم: هذا التطبيق لا يفعّل Root ولا يستغل ثغرات. يجب أن يكون Root مفعّلاً مسبقاً بواسطة المستخدم ومدير موثوق.';
}
