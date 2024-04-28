package com.github.alist.utils

import com.github.alist.bean.FindVideoRecordResp
import com.github.alist.bean.VideoItem
import io.flutter.plugin.common.MethodChannel

object FlutterMethods {
    lateinit var channel: MethodChannel

    fun findVideoRecordByPath(path: String, callback: (FindVideoRecordResp) -> Unit) {
        channel.invokeMethod(
            "findVideoRecordByPath",
            mutableMapOf("path" to path),
            object : MethodChannel.Result {

                override fun success(result: Any?) {
                    if (result is String) {
                        callback(GsonUtils.parseObject(result))
                    }
                }

                override fun error(p0: String, p1: String?, p2: Any?) {
                }

                override fun notImplemented() {
                }
            })
    }

    fun deleteVideoRecord(path: String) {
        channel.invokeMethod(
            "deleteVideoRecord",
            mutableMapOf("path" to path)
        )
    }

    fun insertOrUpdateVideoRecord(
        path: String,
        videoCurrentPosition: Long,
        videoDuration: Long,
        sign: String?
    ) {
        channel.invokeMethod(
            "insertOrUpdateVideoRecord",
            mutableMapOf(
                "path" to path,
                "videoCurrentPosition" to videoCurrentPosition,
                "videoDuration" to videoDuration,
                "sign" to sign
            )
        )
    }

    fun onPayerDestroyed() {
        channel.invokeMethod("onPayerDestroyed", "")
    }

    fun addFileViewingRecord(video: VideoItem) {
        channel.invokeMethod(
            "addFileViewingRecord",
            mutableMapOf(
                "path" to video.remotePath,
                "name" to video.name,
                "sign" to video.sign,
                "size" to video.size,
                "thumb" to video.thumb,
                "modifiedMilliseconds" to video.modifiedMilliseconds,
                "provider" to video.provider
            )
        )
    }
}