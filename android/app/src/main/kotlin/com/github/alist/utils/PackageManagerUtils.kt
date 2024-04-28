package com.github.alist.utils

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import androidx.core.graphics.drawable.toBitmap
import com.github.alist.bean.ExternalPlayer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File

object PackageManagerUtils {
    suspend fun loadExternalPlayerList(context: Context): List<ExternalPlayer> {
        return withContext(Dispatchers.IO) {
            val packageManager: PackageManager = context.packageManager
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(Uri.parse("http://a.com/test.mp4"), "video/*")
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)

            val resultList = mutableListOf<ExternalPlayer>()
            for (resolveInfo in resolveInfos) {
                val label = resolveInfo.activityInfo.loadLabel(packageManager)

                val file =
                    File(context.cacheDir, "appIcon/${resolveInfo.activityInfo.packageName}.webp")
                if (!file.exists()) {
                    file.parentFile?.mkdirs()
                    val appIcon = resolveInfo.loadIcon(packageManager)
                    val bitmap = appIcon.toBitmap()
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        bitmap.compress(
                            Bitmap.CompressFormat.WEBP_LOSSLESS,
                            100,
                            byteArrayOutputStream
                        )
                    } else {
                        bitmap.compress(Bitmap.CompressFormat.WEBP, 100, byteArrayOutputStream)
                    }
                    val byteArray = byteArrayOutputStream.toByteArray()

                    val tmpFile = File("${file.absolutePath}.tmp")
                    tmpFile.writeBytes(byteArray)
                    tmpFile.renameTo(file)
                }

                resultList.add(
                    ExternalPlayer(
                        packageName = resolveInfo.activityInfo.packageName,
                        activity = resolveInfo.activityInfo.name,
                        label = label.toString(),
                        icon = file.absolutePath
                    )
                )
            }
            resultList
        }
    }
}