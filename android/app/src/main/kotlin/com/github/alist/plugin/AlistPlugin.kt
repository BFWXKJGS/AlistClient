package com.github.alist.plugin

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import com.github.alist.DownloadingNotificationService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import okio.buffer
import okio.sink
import okio.source
import java.io.File

class AlistPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.github.alist.client.plugin")
        context = binding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAppInstalled" -> {
                isAppInstalled(call, result)
            }

            "launchApp" -> {
                launchApp(call, result)
            }

            "isScopedStorage" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    result.success(true)
                } else {
                    result.success(false)
                }
            }

            "onDownloadingStart" -> {
                context.startService(Intent(context, DownloadingNotificationService::class.java))
                result.success(null)
            }

            "onDownloadingEnd" -> {
                context.stopService(Intent(context, DownloadingNotificationService::class.java))
                result.success(null)
            }

            "saveFileToLocal" -> {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                saveFileToLocal(result, call)
            }
            "getExternalDownloadDir" ->{
                result.success(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).path)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun isFileExistsInDownloadDirectory(fileName: String): Boolean {
        var result = false
        val contentResolver: ContentResolver = context.contentResolver
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(
            MediaStore.Downloads.DISPLAY_NAME
        )
        val selection = MediaStore.Downloads.DISPLAY_NAME + "=?"
        val selectionArgs = arrayOf(fileName)

        val cursor = contentResolver.query(collection, projection, selection, selectionArgs, null)

        if (cursor != null && cursor.count > 0) {
            result = true
        }
        cursor?.close()
        return result
    }

    private fun saveFileToLocal(
        result: MethodChannel.Result,
        call: MethodCall
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "-1",
                "'saveFileToLocal' just support api version above android Q.",
                null
            )
            return
        }
        val filePath: String? = call.argument("filePath")
        var fileName: String? = call.argument("fileName")
        if (filePath.isNullOrEmpty()) {
            result.error("-1", "filePath not exists.", null)
            return
        }
        if (fileName.isNullOrEmpty()) {
            result.error("-1", "fileName not exists.", null)
            return
        }
        var fileNameIndex = 0
        while (isFileExistsInDownloadDirectory(fileName!!)) {
            val extIndex = fileName.indexOf('.')
            var ext = ""
            var fileNameWithoutExt: String
            if (extIndex > -1) {
                ext = ".${fileName.substringAfterLast(".")}"
                fileNameWithoutExt = fileName.substringBeforeLast(".")
            } else {
                fileNameWithoutExt = fileName
            }
            fileNameIndex++
            fileName = "$fileNameWithoutExt($fileNameIndex)$ext"
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            val fileExtension = MimeTypeMap.getFileExtensionFromUrl(fileName)
            var mimeType =
                MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension)
            if (mimeType.isNullOrEmpty()) {
                mimeType = "application/octet-stream"
            }

            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }

        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)

        uri?.let {
            resolver.openOutputStream(uri)?.use { output ->
                output.sink().buffer().use { sink ->
                    File(filePath).inputStream().source().buffer().use { source ->
                        sink.writeAll(source)
                    }
                }
            }
        }
        result.success(1)
    }

    private fun launchApp(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val packageName: String? = call.argument("packageName")
        val uri: String? = call.argument("uri")
        if (packageName.isNullOrEmpty()) {
            result.error("INVALID_PACKAGE_NAME", "The package name is invalid", null)
            return
        }
        if (uri.isNullOrEmpty()) {
            try {
                val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                context.startActivity(intent)
                result.success(true)
            } catch (exc: PackageManager.NameNotFoundException) {
                result.success(false)
            }
        } else {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse(uri)
                    setPackage(packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                result.success(true)
            } catch (exc: PackageManager.NameNotFoundException) {
                result.success(false)
            }
        }
    }

    private fun isAppInstalled(
        call: MethodCall, result: MethodChannel.Result
    ) {
        val packageName: String? = call.argument("packageName")
        if (packageName.isNullOrEmpty()) {
            result.error("INVALID_PACKAGE_NAME", "The package name is invalid", null)
            return
        }

        try {
            val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
            val isInstalled = packageInfo.applicationInfo.enabled
            result.success(isInstalled)
        } catch (exc: PackageManager.NameNotFoundException) {
            result.success(false)
        }
    }
}