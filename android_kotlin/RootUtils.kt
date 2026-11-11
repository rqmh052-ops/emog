package com.Bayan.emoji.app

import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

internal data class RootCommandResult(
    val success: Boolean,
    val exitCode: Int,
    val output: String,
    val timedOut: Boolean = false
)

internal object RootUtils {
    const val MODULE_ID = "iOS26.4Unicode17"
    const val FONT_ENTRY = "system/fonts/NotoColorEmoji.ttf"
    const val BASE_NAME = "ios_emoji.zip"
    const val CUSTOM_NAME = "custom_module.zip"
    const val MIN_FONT_BYTES = 10_000L
    private const val MODULE_COPY = "/data/local/tmp/ios_emoji_root_module.zip"

    // يحدد أدوات إدارة الوحدات المتاحة (KernelSU / APatch / Magisk) حتى لو لم تكن في PATH.
    private val PRELUDE = """
        KSUD=§(command -v ksud 2>/dev/null)
        [ -z "§KSUD" ] && for p in /data/adb/ksud /data/adb/ksu/bin/ksud; do [ -x "§p" ] && KSUD="§p" && break; done
        APD=§(command -v apd 2>/dev/null)
        [ -z "§APD" ] && [ -x /data/adb/apd ] && APD=/data/adb/apd
        MAGISK=§(command -v magisk 2>/dev/null)
        true
    """

    // الرمز § يُستبدل بـ $ كي تبقى سكربتات الشيل مقروءة داخل نصوص Kotlin الخام.
    private fun sh(body: String): String =
        (PRELUDE.trimIndent() + "\n" + body.trimIndent()).replace('§', '$')

    fun probeRoot(): Map<String, Any> {
        val path = System.getenv("PATH") ?: "/system/bin:/system/xbin:/vendor/bin"
        val suFound = path.split(":").any { File(it, "su").canExecute() } ||
            listOf("/system/bin/su", "/system/xbin/su", "/sbin/su", "/debug_ramdisk/su").any { File(it).canExecute() }
        val manager = when {
            File("/data/adb/ksu").exists() -> "KernelSU"
            File("/data/adb/ap").exists() -> "APatch"
            File("/data/adb/magisk").exists() || File("/sbin/.magisk").exists() -> "Magisk"
            suFound -> "su متاح؛ المدير غير معروف"
            else -> "غير مكتشف"
        }
        return mapOf("suFound" to suFound, "manager" to manager)
    }

    fun requestRoot(): Map<String, Any> {
        val result = runAsRoot("id -u", 45_000)
        val granted = result.success && result.output.lineSequence().any { it.trim() == "0" }
        val manager = if (granted) detectManagerAsRoot() else "غير معروف"
        return mapOf(
            "granted" to granted,
            "output" to result.output,
            "exitCode" to result.exitCode,
            "timedOut" to result.timedOut,
            "manager" to manager
        )
    }

    private fun detectManagerAsRoot(): String {
        val r = runAsRoot(
            sh("""if [ -n "§KSUD" ]; then echo KernelSU; elif [ -n "§APD" ]; then echo APatch; elif [ -n "§MAGISK" ]; then echo Magisk; else echo su; fi"""),
            8_000
        )
        return r.output.trim().lineSequence().lastOrNull()?.ifBlank { "غير معروف" } ?: "غير معروف"
    }

    fun listModules(): Map<String, Any> {
        val script = sh(
            """
            if [ -n "§KSUD" ]; then
              "§KSUD" module list 2>&1
              code=§?
              for d in /data/adb/modules/*; do
                [ -d "§d" ] || continue
                [ -f "§d/remove" ] && continue
                if [ -f "§d/module.prop" ] && grep -Eiq '^metamodule=(1|true)§' "§d/module.prop"; then
                  echo "APP_METAMODULE:§{d##*/}"
                fi
              done
              exit §code
            elif [ -d /data/adb/modules ]; then
              for d in /data/adb/modules/*; do
                [ -d "§d" ] || continue
                [ -f "§d/remove" ] && continue
                echo "§{d##*/}"
              done
            else
              echo 'مدير الوحدات غير موجود'
              exit 2
            fi
            """
        )
        val r = runAsRoot(script, 20_000)
        return mapOf("success" to r.success, "output" to r.output, "exitCode" to r.exitCode)
    }

    fun inspectFontArchive(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.isFile) return mapOf("success" to false, "error" to "ملف الموديل غير موجود")
        return try {
            ZipFile(file).use { zip ->
                val prop = zip.getEntry("module.prop")
                    ?: return mapOf("success" to false, "error" to "module.prop غير موجود داخل الأرشيف")
                val propText = zip.getInputStream(prop).bufferedReader().use { it.readText() }
                val id = propText.lineSequence().firstOrNull { it.startsWith("id=") }
                    ?.substringAfter("=")?.trim().orEmpty()
                val font = zip.getEntry(FONT_ENTRY)
                mapOf(
                    "success" to (id == MODULE_ID && font != null),
                    "moduleId" to id,
                    "fontSize" to (font?.size ?: -1L),
                    "zipSize" to file.length()
                )
            }
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "تعذر قراءة الأرشيف"))
        }
    }

    // يستورد ملف مستخدم: موديل ZIP جاهز، أو ملف خط TTF يُدمج داخل الموديل المرفق.
    fun importFont(path: String, filesDir: File, cacheDir: File): Map<String, Any> {
        val src = try { File(path).canonicalFile } catch (e: Exception) {
            return mapOf("success" to false, "error" to "مسار غير صالح")
        }
        val allowed = listOf(filesDir, cacheDir).any { src.path.startsWith(it.canonicalPath + File.separator) }
        if (!allowed || !src.isFile || src.length() <= 0L) {
            return mapOf("success" to false, "error" to "الملف المحدد غير صالح")
        }
        val out = File(filesDir, CUSTOM_NAME)
        val head = ByteArray(4)
        val n = src.inputStream().use { it.read(head) }
        if (n < 4) return mapOf("success" to false, "error" to "الملف صغير جداً")
        val isZip = head[0] == 'P'.code.toByte() && head[1] == 'K'.code.toByte()
        val isFont = head.contentEquals(byteArrayOf(0, 1, 0, 0)) ||
            String(head, Charsets.ISO_8859_1) in setOf("OTTO", "true", "ttcf")
        try {
            when {
                isZip -> {
                    val info = inspectFontArchive(src.path)
                    if (info["success"] != true) {
                        return mapOf("success" to false, "error" to (info["error"] ?: "الأرشيف ليس موديل $MODULE_ID صالحاً"))
                    }
                    val size = (info["fontSize"] as? Long) ?: -1L
                    if (size < MIN_FONT_BYTES) {
                        return mapOf("success" to false, "error" to "ملف الخط داخل الموديل فارغ أو صغير جداً")
                    }
                    src.copyTo(out, overwrite = true)
                }
                isFont -> {
                    if (src.length() < MIN_FONT_BYTES) {
                        return mapOf("success" to false, "error" to "ملف الخط صغير جداً")
                    }
                    val base = File(filesDir, BASE_NAME)
                    if (!base.isFile) return mapOf("success" to false, "error" to "الموديل الأساسي غير جاهز، أعد فتح التطبيق")
                    buildModuleWithFont(base, src, out)
                }
                else -> return mapOf("success" to false, "error" to "نوع الملف غير مدعوم. اختر ملف ‎.ttf‎ أو موديل ‎.zip‎")
            }
        } catch (e: Exception) {
            return mapOf("success" to false, "error" to (e.message ?: "فشل الاستيراد"))
        } finally {
            if (src.path.startsWith(cacheDir.canonicalPath + File.separator) ||
                src.name == "import_tmp") src.delete()
        }
        val info = inspectFontArchive(out.path)
        return if (info["success"] == true) info else mapOf("success" to false, "error" to "فشل التحقق من الموديل الناتج")
    }

    private fun buildModuleWithFont(base: File, ttf: File, out: File) {
        val tmp = File(out.parentFile, out.name + ".tmp")
        ZipFile(base).use { zip ->
            ZipOutputStream(tmp.outputStream().buffered()).use { zos ->
                val entries = zip.entries()
                while (entries.hasMoreElements()) {
                    val e = entries.nextElement()
                    zos.putNextEntry(ZipEntry(e.name))
                    if (!e.isDirectory) {
                        if (e.name == FONT_ENTRY) ttf.inputStream().use { it.copyTo(zos) }
                        else zip.getInputStream(e).use { it.copyTo(zos) }
                    }
                    zos.closeEntry()
                }
            }
        }
        if (out.exists()) out.delete()
        if (!tmp.renameTo(out)) {
            tmp.copyTo(out, overwrite = true)
            tmp.delete()
        }
    }

    fun deleteCustom(filesDir: File): Map<String, Any> {
        val f = File(filesDir, CUSTOM_NAME)
        val ok = !f.exists() || f.delete()
        return mapOf("success" to ok)
    }

    fun installModule(path: String, appFilesDir: File): Map<String, Any> {
        val file = File(path).canonicalFile
        val allowedRoot = appFilesDir.canonicalFile
        if (!file.path.startsWith(allowedRoot.path + File.separator) || !file.isFile || file.length() <= 0L) {
            return mapOf("success" to false, "output" to "مسار ملف الموديل غير صالح")
        }
        val inspected = inspectFontArchive(file.path)
        if (inspected["success"] != true) {
            return mapOf("success" to false, "output" to "ملف الموديل غير مطابق أو معرّف الموديل غير صحيح")
        }
        val fontSize = (inspected["fontSize"] as? Long) ?: -1L
        if (fontSize < MIN_FONT_BYTES) {
            return mapOf("success" to false, "output" to "ملف الخط داخل الموديل فارغ. استورد ملف الخط أولاً.")
        }
        val script = sh(
            """
            set -e
            trap 'rm -f $MODULE_COPY' EXIT
            cp ${shellQuote(file.path)} '$MODULE_COPY'
            chmod 0644 '$MODULE_COPY'
            if [ -n "§KSUD" ]; then
              "§KSUD" module install '$MODULE_COPY'
            elif [ -n "§APD" ]; then
              "§APD" module install '$MODULE_COPY'
            elif [ -n "§MAGISK" ]; then
              "§MAGISK" --install-module '$MODULE_COPY'
            else
              echo 'لم يتم العثور على ksud أو apd أو magisk'
              exit 127
            fi
            """
        )
        val r = runAsRoot(script, 120_000)
        return mapOf("success" to r.success, "output" to r.output, "exitCode" to r.exitCode, "fontSize" to fontSize)
    }

    fun removeModule(moduleId: String): Map<String, Any> {
        if (moduleId != MODULE_ID) return mapOf("success" to false, "output" to "معرّف موديل غير مسموح")
        val script = sh(
            """
            if [ -n "§KSUD" ]; then
              "§KSUD" module uninstall '$MODULE_ID'
            elif [ -n "§APD" ]; then
              "§APD" module uninstall '$MODULE_ID'
            elif [ -d '/data/adb/modules/$MODULE_ID' ]; then
              touch '/data/adb/modules/$MODULE_ID/remove'
            else
              echo 'الموديل غير موجود'
              exit 2
            fi
            """
        )
        val r = runAsRoot(script, 30_000)
        return mapOf("success" to r.success, "output" to r.output, "exitCode" to r.exitCode)
    }

    fun setAllModulesDisabled(disabled: Boolean): Map<String, Any> {
        val verb = if (disabled) "disable" else "enable"
        val fileOp = if (disabled) "touch \"§d/disable\"" else "rm -f \"§d/disable\""
        val script = sh(
            """
            set -e
            [ -d /data/adb/modules ] || { echo 'مجلد الموديلات غير موجود'; exit 2; }
            for d in /data/adb/modules/*; do
              [ -d "§d" ] || continue
              id="§{d##*/}"
              if [ -n "§KSUD" ]; then
                "§KSUD" module $verb "§id"
              elif [ -n "§APD" ]; then
                "§APD" module $verb "§id"
              else
                $fileOp
              fi
            done
            """
        )
        val r = runAsRoot(script, 60_000)
        return mapOf("success" to r.success, "output" to r.output, "exitCode" to r.exitCode)
    }

    fun softReboot(): Map<String, Any> {
        val script = sh(
            """
            if [ -n "§KSUD" ]; then
              "§KSUD" soft-reboot && exit 0
            fi
            setprop ctl.restart zygote || { stop; start; }
            """
        )
        val r = runAsRoot(script, 8_000)
        return mapOf("success" to (r.success || r.timedOut), "output" to r.output, "timedOut" to r.timedOut)
    }

    private fun shellQuote(value: String): String = "'" + value.replace("'", "'\\''") + "'"

    private fun runAsRoot(command: String, timeoutMs: Long): RootCommandResult {
        val process = try {
            ProcessBuilder("su", "-c", command).redirectErrorStream(true).start()
        } catch (e: Exception) {
            return RootCommandResult(false, -1, e.message ?: "تعذر تشغيل su")
        }
        val bytes = ByteArrayOutputStream()
        val reader = Thread {
            try { process.inputStream.use { it.copyTo(bytes) } } catch (_: Exception) { }
        }
        reader.isDaemon = true
        reader.start()
        val finished = try { process.waitFor(timeoutMs, TimeUnit.MILLISECONDS) } catch (_: InterruptedException) { false }
        if (!finished) {
            process.destroy()
            try { process.waitFor(500, TimeUnit.MILLISECONDS) } catch (_: Exception) { }
            if (process.isAlive) process.destroyForcibly()
        }
        try { reader.join(1_000) } catch (_: InterruptedException) { }
        val output = bytes.toString(Charsets.UTF_8.name()).trim()
        return if (finished) {
            val code = process.exitValue()
            RootCommandResult(code == 0, code, output)
        } else {
            RootCommandResult(false, -1, if (output.isEmpty()) "انتهت مهلة تنفيذ أمر Root" else output, true)
        }
    }
}
