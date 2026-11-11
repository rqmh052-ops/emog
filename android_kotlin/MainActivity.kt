package com.Bayan.emoji.app

import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.Bayan.emoji.app/root"
    private val executor    = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // ── device / version info ───────────────────────────────────────
                    "getDeviceInfo"    -> result.success(getDeviceInfo())
                    "getVersionCode"   -> result.success(getVersionCode())
                    "getFilesDir"      -> result.success(filesDir.absolutePath)

                    // ── existing root probe / request ────────────────────────────────
                    "probeRoot"  -> result.success(RootUtils.probeRoot())
                    "requestRoot"-> runAsync(result) { RootUtils.requestRoot() }

                    // ── module management ────────────────────────────────────────────
                    "listModules" -> runAsync(result) { RootUtils.listModules() }
                    "installModule" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank())
                            result.success(mapOf("success" to false, "output" to "مسار غير محدد"))
                        else runAsync(result) { RootUtils.installModule(path, filesDir) }
                    }
                    "removeModule" -> {
                        val id = call.argument<String>("moduleId") ?: ""
                        runAsync(result) { RootUtils.removeModule(id) }
                    }
                    "setAllModulesDisabled" -> {
                        val disabled = call.argument<Boolean>("disabled") ?: false
                        runAsync(result) { RootUtils.setAllModulesDisabled(disabled) }
                    }

                    // ── font archive helpers ─────────────────────────────────────────
                    "inspectFontArchive" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank())
                            result.success(mapOf("success" to false, "error" to "مسار غير محدد"))
                        else runAsync(result) { RootUtils.inspectFontArchive(path) }
                    }
                    "importFont" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank())
                            result.success(mapOf("success" to false, "error" to "مسار غير محدد"))
                        else runAsync(result) { RootUtils.importFont(path, filesDir, cacheDir) }
                    }
                    "deleteCustom" -> runAsync(result) { RootUtils.deleteCustom(filesDir) }

                    // ── soft reboot ─────────────────────────────────────────────────
                    "softReboot" -> runAsync(result) { RootUtils.softReboot() }

                    // ══════════════════════════════════════════════════════════════════
                    // DFRoot / DirtyFrag exploit methods
                    // ══════════════════════════════════════════════════════════════════

                    /** runExploit — triggers CVE-2026-43284 (DirtyFrag) exploit.
                     *  args: koPath (String), softReboot (Bool), disableModules (Bool)
                     *  returns: {success, log}
                     */
                    "runExploit" -> {
                        val koPath = call.argument<String>("koPath") ?: ""
                        val softR  = call.argument<Boolean>("softReboot") ?: false
                        val disM   = call.argument<Boolean>("disableModules") ?: false
                        if (koPath.isBlank()) {
                            result.success(mapOf("success" to false, "log" to "koPath missing"))
                        } else {
                            executor.execute {
                                val r = ExploitBridge.runExploit(
                                    applicationContext, koPath, softR, disM)
                                mainHandler.post {
                                    result.success(mapOf(
                                        "success" to r.success,
                                        "log"     to r.log))
                                }
                            }
                        }
                    }

                    /** getExploitLog — returns accumulated log lines during/after exploit */
                    "getExploitLog" -> result.success(mapOf(
                        "log"     to ExploitBridge.getLog(),
                        "running" to ExploitBridge.isRunning()))

                    /** checkKsud — checks if KernelSU (ksud) is active */
                    "checkKsud" -> runAsync(result) { ExploitBridge.checkKsudRunning() }

                    /** grantSelfRoot — grants root to our UID via KernelSU UAPI */
                    "grantSelfRoot" -> {
                        val uid = call.argument<Int>("uid") ?: android.os.Process.myUid()
                        runAsync(result) { ExploitBridge.grantSelfRoot(uid) }
                    }

                    /** stageKsud — extracts bundled ksud asset to device dir */
                    "stageKsud" -> {
                        executor.execute {
                            val ok = ExploitBridge.stageKsud(applicationContext)
                            mainHandler.post { result.success(mapOf("success" to ok)) }
                        }
                    }

                    /** detectKmi — returns KMI string from /proc/version */
                    "detectKmi" -> result.success(mapOf("kmi" to detectKmi()))

                    /** extractKo — copies the right bundled .ko to filesDir */
                    "extractKo" -> {
                        val kmi = call.argument<String>("kmi") ?: ""
                        runAsync(result) { extractKo(kmi) }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── KMI detection ──────────────────────────────────────────────────────

    private fun detectKmi(): String {
        return try {
            val release = File("/proc/version").readText()
            // e.g. "... android15-6.6.30-android15-8-g... ..."
            val rx = Regex("android(\\d+)-(\\d+\\.\\d+)")
            val match = rx.find(release)
            if (match != null) "android${match.groupValues[1]}-${match.groupValues[2]}" else ""
        } catch (_: Exception) { "" }
    }

    private fun extractKo(kmi: String): Map<String, Any> {
        val assetName = when {
            kmi.contains("android12") && kmi.contains("5.10") -> "kmi/android12-5.10.ko"
            kmi.contains("android13") && kmi.contains("5.10") -> "kmi/android13-5.10.ko"
            kmi.contains("android13") && kmi.contains("5.15") -> "kmi/android13-5.15.ko"
            kmi.contains("android14") && kmi.contains("5.15") -> "kmi/android14-5.15.ko"
            kmi.contains("android14") && kmi.contains("6.1")  -> "kmi/android14-6.1.ko"
            kmi.contains("android15") && kmi.contains("6.6")  -> "kmi/android15-6.6.ko"
            kmi.contains("android16") && kmi.contains("6.12") -> "kmi/android16-6.12.ko"
            kmi.contains("android17") && kmi.contains("6.18") -> "kmi/android17-6.18.ko"
            else -> return mapOf("success" to false,
                                 "error" to "لا يوجد .ko مناسب لـ $kmi",
                                 "koPath" to "")
        }
        return try {
            val dest = File(filesDir, "kernelsu.ko")
            assets.open(assetName).use { src ->
                dest.outputStream().use { dst -> src.copyTo(dst) }
            }
            mapOf("success" to true, "koPath" to dest.absolutePath)
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "فشل الاستخراج"), "koPath" to "")
        }
    }

    // ── utility ────────────────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    private fun getVersionCode(): Int = try {
        val info = packageManager.getPackageInfo(packageName, 0)
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode.toInt() else info.versionCode
    } catch (_: Exception) { 1 }

    private fun getDeviceInfo(): Map<String, Any> {
        val kernel = System.getProperty("os.version")
            ?: try { File("/proc/version").readText().trim().take(140) } catch (_: Exception) { "unknown" }
        return mapOf(
            "manufacturer"  to Build.MANUFACTURER,
            "model"         to Build.MODEL,
            "device"        to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdk"           to Build.VERSION.SDK_INT,
            "kernelVersion" to kernel,
            "kmi"           to detectKmi()
        )
    }

    private fun runAsync(result: MethodChannel.Result, action: () -> Map<String, Any>) {
        executor.execute {
            val response = try { action() } catch (e: Exception) {
                mapOf("success" to false,
                      "output"  to (e.message ?: "unknown error"),
                      "error"   to (e.message ?: "unknown error"))
            }
            mainHandler.post { result.success(response) }
        }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
