package com.github.alist

import android.content.Context
import androidx.multidex.MultiDex
import com.shuyu.gsyvideoplayer.GSYVideoManager
import com.shuyu.gsyvideoplayer.model.VideoOptionModel
import io.flutter.app.FlutterApplication
import tv.danmaku.ijk.media.player.IjkMediaPlayer


class App : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        val gsyOptionModelList = mutableListOf<VideoOptionModel>()
        // 丢帧解决音视频不同步的文
        val videoOptionMode01 = VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", 1)
        val videoOptionMode02 =
            VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", 0)

        // url切换400/404（http与https域名共用等）
        val videoOptionMode03 =
            VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_clear", 1)
        val videoOptionMode04 =
            VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", -1)
        gsyOptionModelList.add(videoOptionMode01)
        gsyOptionModelList.add(videoOptionMode02)
        gsyOptionModelList.add(videoOptionMode03)
        gsyOptionModelList.add(videoOptionMode04)
        GSYVideoManager.instance().optionModelList = gsyOptionModelList
    }

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}