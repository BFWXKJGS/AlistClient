package com.github.alist

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.github.alist.client.R

class DownloadingNotificationService : Service() {
    companion object {
        const val channelId = "com.github.alist.client.download"
        const val channelName = "Download"
    }

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.downloading_notification_title))
            .setContentText(getString(R.string.downloading_notification_content))
            .setAutoCancel(false)
            .setOngoing(true)
            .build()
        startForeground(1, notification)
        return super.onStartCommand(intent, flags, startId)
    }
}