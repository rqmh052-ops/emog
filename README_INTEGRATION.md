# دليل دمج ملفات DFRoot في مشروع emoji_root

## الملفات في هذه الحزمة

### ملفات Dart (تذهب إلى `lib/` مباشرة)
| الملف | الوصف |
|-------|-------|
| `exploit_engine.dart` | **جديد** — محرك الـ Exploit كامل (فئة ExploitEngine) |
| `app_settings.dart` | **محدّث** — أُضيف: exploitStartOnBoot، exploitAutoSoftReboot |
| `settings_screen.dart` | **محدّث** — أُضيف قسم "تفعيل الروت الكيرنلي (DFRoot)" |
| `strings.dart` | **محدّث** — أُضيف extension ExploitStrings |

### ملفات Kotlin
| الملف | الوجهة |
|-------|--------|
| `MainActivity.kt` | `android/app/src/main/kotlin/com/Bayan/emoji/app/` |
| `ExploitBridge.kt` | `android/app/src/main/kotlin/com/Bayan/emoji/app/` |
| `BootReceiver.kt` | `android/app/src/main/kotlin/com/Bayan/emoji/app/` |
| `ExploitBootService.kt` | `android/app/src/main/kotlin/com/Bayan/emoji/app/` |

### ملفات C (Native Exploit)
| الملف | الوجهة |
|-------|--------|
| `exp.c` | `android/app/src/main/cpp/` |
| `bootstrap.c` | `android/app/src/main/cpp/` |
| `elf_parser.c` | `android/app/src/main/cpp/` |
| `splicehelper.c` | `android/app/src/main/cpp/` |
| `d2_launch.c` | `android/app/src/main/cpp/` ← Samsung DMC launcher |
| `libcxx.S` | `android/app/src/main/cpp/` |
| `aes256.h` | `android/app/src/main/cpp/` |
| `include.inc` | `android/app/src/main/cpp/` |
| `CMakeLists.txt` | `android/app/src/main/cpp/` |

---

## خطوات الدمج

### 1. نسخ ملفات Dart
```bash
cp exploit_engine.dart  <project>/lib/
cp app_settings.dart    <project>/lib/
cp settings_screen.dart <project>/lib/
# ثم أضف الأسطر من strings.dart يدوياً أو استبدل الملف كاملاً
```

### 2. نسخ ملفات Kotlin
```bash
DST=<project>/android/app/src/main/kotlin/com/Bayan/emoji/app
cp ExploitBridge.kt       $DST/
cp BootReceiver.kt        $DST/
cp ExploitBootService.kt  $DST/
cp MainActivity.kt        $DST/
```

### 3. نسخ ملفات C
```bash
CPP=<project>/android/app/src/main/cpp
mkdir -p $CPP
cp exp.c bootstrap.c elf_parser.c splicehelper.c \
   d2_launch.c libcxx.S aes256.h include.inc CMakeLists.txt $CPP/
```

### 4. إضافة assets
```bash
ASSETS=<project>/assets
mkdir -p $ASSETS/kmi
# انسخ ملفات من kernelsu-samsung/
cp ksud-aarch64-linux-android       $ASSETS/ksud
cp ksuinit-aarch64                  $ASSETS/ksuinit
cp android12-5.10_kernelsu.ko       $ASSETS/kmi/android12-5.10.ko
cp android13-5.10_kernelsu.ko       $ASSETS/kmi/android13-5.10.ko
cp android13-5.15_kernelsu.ko       $ASSETS/kmi/android13-5.15.ko
cp android14-5.15_kernelsu.ko       $ASSETS/kmi/android14-5.15.ko
cp android14-6.1_kernelsu.ko        $ASSETS/kmi/android14-6.1.ko
cp android15-6.6_kernelsu.ko        $ASSETS/kmi/android15-6.6.ko
cp android16-6.12_kernelsu.ko       $ASSETS/kmi/android16-6.12.ko
cp android17-6.18_kernelsu.ko       $ASSETS/kmi/android17-6.18.ko
# ضع iOS_26_4__Unicode_17_.zip مكان الـ placeholder
cp "iOS_26_4__Unicode_17_.zip"      $ASSETS/ios_emoji.zip
```

### 5. تحديث pubspec.yaml
استبدل `pubspec.yaml` بالنسخة الموجودة هنا.

### 6. تحديث AndroidManifest.xml
أضف الأسطر من `AndroidManifest_additions.xml` داخل:
- `<manifest>` → أضف الـ `<uses-permission>` السبعة
- `<application>` → أضف `<receiver>` و `<service>`

### 7. تحديث build.gradle
أضف الأسطر من `build_gradle_additions.txt` داخل `android { ... }`.

---

## الاختبار

```bash
cd <project>
flutter pub get
flutter build apk --release --target-platform android-arm64
```

---

## تسلسل عمل التطبيق بعد الدمج

```
الشاشة الرئيسية
  └─ [إذا لا يوجد روت] → رسالة: "اذهب للإعدادات لتفعيل الروت"
  └─ [إذا يوجد روت موجود] → يعمل مباشرة (Magisk/APatch/KSU العادي)

الإعدادات → قسم "تفعيل الروت الكيرنلي"
  ① [تفعيل] زر ← يُشغّل DFRoot exploit
       ↓
  ② [منح Root] زر ← ksud app-profile --uid <myUid>
       ↓
  الإعدادات → تشغيل عند الإقلاع (OFF افتراضياً)
  الإعدادات → إعادة تشغيل الواجهة بعد الـ Exploit (OFF افتراضياً)
```

---

## ملاحظات مهمة

- **الروت مؤقت**: يختفي بعد إعادة تشغيل الجهاز كاملة
- **موديل الخط دائم**: مثبّت في `/data/adb/modules/` ولن يُحذف بإعادة التشغيل
- **android14-6.1**: قد لا يعمل — التطبيق يحذّر لكن لا يمنع المحاولة
- **الملف ios_emoji.zip**: الموديل بداخله placeholder (0 bytes) — ضع الملف الحقيقي (35MB) قبل البناء النهائي
