"""يجهّز مشروع أندرويد المولَّد بـ `flutter create` ليصبح تطبيق «روت الإيموجي».

يعمل في CI فقط: كل ملفات المشروع في الجذر (مثل بيان)، وهذا السكربت يوزّعها
في الأماكن التي يشترطها Flutter/Gradle. لا يحتاج إلا Pillow للأيقونة.
"""
from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ANDROID = ROOT / "android"
MAIN = ANDROID / "app" / "src" / "main"
APP_PACKAGE = "com.Bayan.emoji.app"
APP_LABEL = "روت الإيموجي"
COMPILE_SDK = 37
MIN_KOTLIN = "2.2.20"
BG_HEX = "#090D14"
ICON_BG = (15, 26, 51, 255)


# ───────── Gradle ─────────
def _vt(v: str) -> tuple:
    return tuple(int(x) for x in re.findall(r"\d+", v)[:3])


def patch_settings() -> None:
    path = ANDROID / "settings.gradle.kts"
    kts = path.exists()
    if not kts:
        path = ANDROID / "settings.gradle"
    text = path.read_text(encoding="utf-8")
    pattern = r'(id\s*\(?\s*["\']org\.jetbrains\.kotlin\.android["\']\s*\)?\s+version\s+["\'])([^"\']+)(["\'])'

    def fix(m: re.Match) -> str:
        return m.group(0) if _vt(m.group(2)) >= _vt(MIN_KOTLIN) else m.group(1) + MIN_KOTLIN + m.group(3)

    text = re.sub(pattern, fix, text, count=1)
    if "org.jetbrains.kotlin.android" not in text and "kotlin-android" not in text:
        line = (
            f'id("org.jetbrains.kotlin.android") version "{MIN_KOTLIN}" apply false'
            if kts
            else f"id 'org.jetbrains.kotlin.android' version '{MIN_KOTLIN}' apply false"
        )
        m = re.search(r"plugins\s*\{(?P<body>[\s\S]*?)\n\}", text)
        if not m:
            raise RuntimeError("تعذر العثور على plugins block في settings.gradle")
        text = text[: m.end(1)] + f"\n    {line}" + text[m.end(1):]
    path.write_text(text, encoding="utf-8")


KTS_SIGNING = """

android {
    signingConfigs {
        create("emojiRelease") {
            val keyPath = System.getenv("EMOJI_KEYSTORE_PATH")
            if (!keyPath.isNullOrBlank()) {
                storeFile = file(keyPath)
                storePassword = System.getenv("EMOJI_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("EMOJI_KEY_ALIAS") ?: "emoji"
                keyPassword = System.getenv("EMOJI_KEYSTORE_PASSWORD")
            }
        }
    }
    buildTypes {
        getByName("release") {
            val keyPath = System.getenv("EMOJI_KEYSTORE_PATH")
            if (!keyPath.isNullOrBlank()) {
                signingConfig = signingConfigs.getByName("emojiRelease")
            }
        }
    }
}
"""

GROOVY_SIGNING = """

android {
    signingConfigs {
        emojiRelease {
            def keyPath = System.getenv("EMOJI_KEYSTORE_PATH")
            if (keyPath != null && !keyPath.trim().isEmpty()) {
                storeFile file(keyPath)
                storePassword System.getenv("EMOJI_KEYSTORE_PASSWORD")
                keyAlias System.getenv("EMOJI_KEY_ALIAS") ?: "emoji"
                keyPassword System.getenv("EMOJI_KEYSTORE_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            def keyPath = System.getenv("EMOJI_KEYSTORE_PATH")
            if (keyPath != null && !keyPath.trim().isEmpty()) {
                signingConfig signingConfigs.emojiRelease
            }
        }
    }
}
"""


def patch_app_build() -> None:
    path = ANDROID / "app" / "build.gradle.kts"
    kts = path.exists()
    if not kts:
        path = ANDROID / "app" / "build.gradle"
    text = path.read_text(encoding="utf-8")
    if kts:
        text = re.sub(r'namespace\s*=\s*"[^"]+"', f'namespace = "{APP_PACKAGE}"', text, count=1)
        text = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{APP_PACKAGE}"', text, count=1)
        text = re.sub(r"compileSdk\s*=\s*[^\n]+", f"compileSdk = {COMPILE_SDK}", text, count=1)
        text += KTS_SIGNING
    else:
        text = re.sub(r"namespace\s*[= ]\s*[\"'][^\"']+[\"']", f'namespace "{APP_PACKAGE}"', text, count=1)
        text = re.sub(r"applicationId\s*(?:=\s*)?[\"'][^\"']+[\"']", f'applicationId "{APP_PACKAGE}"', text, count=1)
        text = re.sub(r"compileSdk(?:Version)?\s*(?:=\s*)?[^\n]+", f"compileSdk {COMPILE_SDK}", text, count=1)
        text += GROOVY_SIGNING
    path.write_text(text, encoding="utf-8")


def patch_gradle_properties() -> None:
    path = ANDROID / "gradle.properties"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    key = "android.suppressUnsupportedCompileSdk"
    if key not in text:
        if text and not text.endswith("\n"):
            text += "\n"
        path.write_text(text + f"{key}={COMPILE_SDK}\n", encoding="utf-8")


# ───────── Kotlin + Manifest + Resources ─────────
MANIFEST = f"""<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- لا توجد أي صلاحيات: التطبيق يعمل بالكامل دون إنترنت. -->
    <application
        android:label="{APP_LABEL}"
        android:name="${{applicationName}}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:supportsRtl="true"
        android:usesCleartextTraffic="false">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
</manifest>
"""

STYLES = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">true</item>
        <item name="android:statusBarColor">@color/app_bg</item>
        <item name="android:navigationBarColor">@color/app_bg</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/app_bg</item>
        <item name="android:statusBarColor">@color/app_bg</item>
        <item name="android:navigationBarColor">@color/app_bg</item>
    </style>
</resources>
"""

STYLES_V31 = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/app_bg</item>
        <item name="android:statusBarColor">@color/app_bg</item>
        <item name="android:navigationBarColor">@color/app_bg</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/app_bg</item>
        <item name="android:statusBarColor">@color/app_bg</item>
        <item name="android:navigationBarColor">@color/app_bg</item>
    </style>
</resources>
"""

COLORS = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="app_bg">{BG_HEX}</color>
    <color name="ic_launcher_background">#0F1A33</color>
</resources>
"""

LAUNCH_BG = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/app_bg" />
</layer-list>
"""

ADAPTIVE = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def install_sources_and_resources() -> None:
    # Kotlin: احذف ما ولّده flutter create وضع ملفاتنا في مسار الحزمة الصحيح
    for d in ("kotlin", "java"):
        shutil.rmtree(MAIN / d, ignore_errors=True)
    kdir = MAIN / "kotlin" / Path(*APP_PACKAGE.split("."))
    kdir.mkdir(parents=True, exist_ok=True)
    for name in ("MainActivity.kt", "RootUtils.kt"):
        shutil.copy2(ROOT / name, kdir / name)

    write(MAIN / "AndroidManifest.xml", MANIFEST)

    # موارد الثيم: احذف النسخ الليلية/القديمة التي كانت ستطغى على الثيم الداكن
    for d in ("values-night", "drawable-v21", "values-night-v31"):
        shutil.rmtree(MAIN / "res" / d, ignore_errors=True)
    write(MAIN / "res" / "values" / "styles.xml", STYLES)
    write(MAIN / "res" / "values-v31" / "styles.xml", STYLES_V31)
    write(MAIN / "res" / "values" / "colors.xml", COLORS)
    write(MAIN / "res" / "drawable" / "launch_background.xml", LAUNCH_BG)


# ───────── الأيقونة: ضع icon.png (خلفية شفافة) في الجذر ─────────
LEGACY = (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192))


def make_icons() -> None:
    from PIL import Image, ImageDraw

    src = ROOT / "icon.png"
    res = MAIN / "res"
    if not src.exists():
        print("icon.png غير موجود: تُترك الأيقونة الافتراضية")
        return
    glyph = Image.open(src).convert("RGBA")
    box = glyph.getbbox()
    if box:
        glyph = glyph.crop(box)
    side = max(glyph.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(glyph, ((side - glyph.width) // 2, (side - glyph.height) // 2))

    # أيقونة تكيفية: الكتابة داخل المنطقة الآمنة (٦٦٪ من اللوحة)
    canvas = 432
    inner = int(canvas * 0.58)
    fg = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    g = square.resize((inner, inner), Image.LANCZOS)
    fg.paste(g, ((canvas - inner) // 2, (canvas - inner) // 2), g)
    (res / "drawable-nodpi").mkdir(parents=True, exist_ok=True)
    fg.save(res / "drawable-nodpi" / "ic_launcher_foreground.png")
    write(res / "mipmap-anydpi-v26" / "ic_launcher.xml", ADAPTIVE)

    # أيقونات قديمة (قبل أندرويد 8): مربع بحواف مدوّرة
    for dpi, px in LEGACY:
        big = px * 4
        base = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(base).rounded_rectangle((0, 0, big - 1, big - 1), radius=big // 5, fill=ICON_BG)
        gg = square.resize((int(big * 0.72), int(big * 0.72)), Image.LANCZOS)
        base.paste(gg, ((big - gg.width) // 2, (big - gg.height) // 2), gg)
        out = res / f"mipmap-{dpi}"
        out.mkdir(parents=True, exist_ok=True)
        base.resize((px, px), Image.LANCZOS).save(out / "ic_launcher.png")


def main() -> None:
    if not ANDROID.exists():
        raise SystemExit("android/ غير موجود: شغّل flutter create أولاً")
    patch_settings()
    patch_app_build()
    patch_gradle_properties()
    install_sources_and_resources()
    make_icons()
    print("android shell ready:", APP_PACKAGE)


if __name__ == "__main__":
    main()
