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
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> result.success(getDeviceInfo())
                    "getVersionCode" -> result.success(getVersionCode())
                    "getFilesDir" -> result.success(filesDir.absolutePath)
                    "probeRoot" -> result.success(RootUtils.probeRoot())
                    "requestRoot" -> runAsync(result) { RootUtils.requestRoot() }
                    "listModules" -> runAsync(result) { RootUtils.listModules() }
                    "inspectFontArchive" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) result.success(mapOf("success" to false, "error" to "مسار الملف غير محدد"))
                        else runAsync(result) { RootUtils.inspectFontArchive(path) }
                    }
                    "importFont" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) result.success(mapOf("success" to false, "error" to "مسار الملف غير محدد"))
                        else runAsync(result) { RootUtils.importFont(path, filesDir, cacheDir) }
                    }
                    "deleteCustom" -> runAsync(result) { RootUtils.deleteCustom(filesDir) }
                    "installModule" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) result.success(mapOf("success" to false, "output" to "مسار الملف غير محدد"))
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
                    "softReboot" -> runAsync(result) { RootUtils.softReboot() }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getVersionCode(): Int {
        return try {
            val info = packageManager.getPackageInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= 28) info.longVersionCode.toInt() else info.versionCode
        } catch (_: Exception) {
            1
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        val kernel = System.getProperty("os.version")
            ?: try { File("/proc/version").readText().trim().take(120) } catch (_: Exception) { "غير معروف" }
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT,
            "kernelVersion" to kernel
        )
    }

    private fun runAsync(result: MethodChannel.Result, action: () -> Map<String, Any>) {
        executor.execute {
            val response = try {
                action()
            } catch (e: Exception) {
                mapOf("success" to false, "output" to (e.message ?: "حدث خطأ غير معروف"), "error" to (e.message ?: "حدث خطأ غير معروف"))
            }
            mainHandler.post { result.success(response) }
        }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
