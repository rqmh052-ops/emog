package com.Bayan.emoji.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BootReceiver — يُشغّل الـ Exploit تلقائياً عند إقلاع الجهاز
 * إذا كان إعداد "التشغيل عند الإقلاع" مفعّلاً.
 *
 * الإعداد مطفأ بالافتراضي — المستخدم يفعّله بنفسه من الإعدادات.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.LOCKED_BOOT_COMPLETED") return

        // قراءة الإعداد من JSON (نفس ملف settings.json الذي تكتبه Flutter)
        val startOnBoot = readStartOnBoot(ctx)
        if (!startOnBoot) return

        ExploitBootService.start(ctx)
    }

    private fun readStartOnBoot(ctx: Context): Boolean {
        return try {
            val f = java.io.File(ctx.filesDir, "settings.json")
            if (!f.exists()) return false
            val text = f.readText()
            // بحث بسيط في JSON بدون مكتبة خارجية
            text.contains("\"exploitStartOnBoot\":true") ||
            text.contains("\"exploitStartOnBoot\": true")
        } catch (_: Exception) { false }
    }
}
