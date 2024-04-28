package com.github.alist.activity

import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.view.ViewGroup.MarginLayoutParams
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.updateLayoutParams
import com.github.alist.bean.VideoItem
import com.github.alist.client.BuildConfig
import com.github.alist.client.R
import com.github.alist.utils.FlutterMethods
import com.github.alist.utils.GsonUtils
import com.github.alist.widget.VisibleChangeListenerImageView
import com.shuyu.gsyvideoplayer.GSYBaseActivityDetail
import com.shuyu.gsyvideoplayer.GSYVideoManager
import com.shuyu.gsyvideoplayer.builder.GSYVideoOptionBuilder
import com.shuyu.gsyvideoplayer.listener.GSYSampleCallBack
import com.shuyu.gsyvideoplayer.listener.GSYVideoProgressListener
import com.shuyu.gsyvideoplayer.player.IjkPlayerManager
import com.shuyu.gsyvideoplayer.player.PlayerFactory
import com.shuyu.gsyvideoplayer.utils.Debuger
import com.shuyu.gsyvideoplayer.utils.OrientationUtils
import com.shuyu.gsyvideoplayer.video.NormalGSYVideoPlayer
import tv.danmaku.ijk.media.exo2.Exo2PlayerManager

class PlayerActivity : GSYBaseActivityDetail<NormalGSYVideoPlayer>(), GSYVideoProgressListener {
    private lateinit var videoPlayer: NormalGSYVideoPlayer
    private lateinit var btnPrevious: View
    private lateinit var btnNext: View
    private lateinit var layoutTop: View
    private lateinit var layoutBottom: View
    private lateinit var bottomProgressbar: View
    private lateinit var btnBack: View
    private lateinit var btnPlayStart: VisibleChangeListenerImageView
    private var videosStr = "[]"
    private var headersStr = "{}"
    private var playerType = ""
    private var videos: List<VideoItem> = emptyList()
    private var headers: Map<String, String> = emptyMap()
    private var index = 0
    private var currentTime = 0L
    private var totalTime = 0L
    private val windowInsetsControllerCompat by lazy {
        WindowInsetsControllerCompat(window, window.decorView)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (BuildConfig.DEBUG) {
            Debuger.enable()
        }
        val args = savedInstanceState ?: intent.extras
        initData(args)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_player)
        findViews()
        initViews()

        if (index >= 0 && videos.size > index) {
            startPlay(index, videos[index])
        }
    }

    private fun initData(args: Bundle?) {
        headersStr = args?.getString("headers") ?: headersStr
        videosStr = args?.getString("videos") ?: videosStr
        index = args?.getInt("index", 0) ?: index
        playerType = args?.getString("playerType") ?: ""
        if (videosStr.isNotEmpty()) {
            videos = GsonUtils.parseList(videosStr)
        }
        if (headersStr.isNotEmpty()) {
            headers = GsonUtils.parseMap(headersStr)
            Debuger.printfLog("headers=$headers")
        }

        if (playerType == "ijkplayer") {
            Debuger.printfError("player = $playerType")
            PlayerFactory.setPlayManager(IjkPlayerManager::class.java)
        } else {
            Debuger.printfError("player = $playerType")
            PlayerFactory.setPlayManager(Exo2PlayerManager::class.java)
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("videos", videosStr)
        outState.putInt("index", index)
    }

    private fun findViews() {
        videoPlayer = findViewById(R.id.video_player)
        btnPrevious = videoPlayer.findViewById(R.id.btn_previous)
        layoutTop = videoPlayer.findViewById(R.id.layout_top)
        layoutBottom = videoPlayer.findViewById(R.id.layout_bottom)
        bottomProgressbar = videoPlayer.findViewById(R.id.bottom_progressbar)
        btnBack = videoPlayer.findViewById(R.id.back)
        btnNext = videoPlayer.findViewById(R.id.btn_next)
        btnPlayStart = videoPlayer.findViewById(R.id.start)
    }

    private fun initViews() {
        videoPlayer.setGSYVideoProgressListener(this)
        orientationUtils = OrientationUtils(this, videoPlayer)
        orientationUtils.isEnable = false

        if (videos.size > 1) {
            btnPlayStart.onVisibleChangeListener = {
                btnPrevious.visibility = it
                btnNext.visibility = it
            }
        }
        btnPrevious.setOnClickListener {
            saveCurrentTime()
            playPrevious()
        }
        btnNext.setOnClickListener {
            saveCurrentTime()
            playNext()
        }

        val gsyVideoOption = GSYVideoOptionBuilder()
        gsyVideoOption
            .setIsTouchWiget(true)
            .setRotateViewAuto(true)
            .setLockLand(false)
            .setAutoFullWithSize(true)
            .setShowFullAnimation(true)
            .setMapHeadData(headers)
            .setNeedLockFull(true)
            .setVideoAllCallBack(object : GSYSampleCallBack() {
                override fun onPrepared(url: String, vararg objects: Any) {
                    super.onPrepared(url, *objects)
                    //开始播放了才能旋转和全屏
                    orientationUtils.isEnable = true
                    isPlay = true
                }

                override fun onAutoComplete(url: String?, vararg objects: Any?) {
                    super.onAutoComplete(url, *objects)
                    if (!isFinishing && index < videos.lastIndex) {
                        FlutterMethods.deleteVideoRecord(videos[index].remotePath)
                        playNext()
                    }
                }

                override fun onEnterFullscreen(url: String?, vararg objects: Any?) {
                    super.onEnterFullscreen(url, *objects)
                    Debuger.printfError("***** onEnterFullscreen **** ");
                }

                override fun onQuitFullscreen(url: String, vararg objects: Any) {
                    super.onQuitFullscreen(url, *objects)
                    Debuger.printfError("***** onQuitFullscreen **** " + objects[0]) //title
                    Debuger.printfError("***** onQuitFullscreen **** " + objects[1]) //当前非全屏player
                    if (orientationUtils != null) {
                        orientationUtils.backToProtVideo()
                    }
                    videoPlayer.post {
                        windowInsetsControllerCompat.show(WindowInsetsCompat.Type.statusBars())
                        windowInsetsControllerCompat.show(WindowInsetsCompat.Type.navigationBars())
                    }
                    btnBack.setOnClickListener {
                        finish()
                    }
                }
            }).setLockClickListener { _, lock ->
                if (orientationUtils != null) {
                    //配合下方的onConfigurationChanged
                    orientationUtils.isEnable = !lock
                }
            }.build(videoPlayer)

        videoPlayer.fullscreenButton.setOnClickListener { //直接横屏
            orientationUtils.resolveByClick()
            //第一个true是否需要隐藏actionbar，第二个true是否需要隐藏statusbar
            videoPlayer.startWindowFullscreen(this@PlayerActivity, true, true)
        }

        ViewCompat.setOnApplyWindowInsetsListener(videoPlayer) { _, insets ->
            val navigationBars = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val statusBars = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            layoutTop.updateLayoutParams<MarginLayoutParams> {
                topMargin = statusBars.top
            }
            layoutBottom.updateLayoutParams<MarginLayoutParams> {
                bottomMargin = navigationBars.bottom
            }
            bottomProgressbar.updateLayoutParams<MarginLayoutParams> {
                bottomMargin = navigationBars.bottom
            }
            insets
        }
    }

    private fun playPrevious() {
        if (index > 0) {
            index -= 1
            currentTime = 0
            totalTime = 0
            startPlay(index, videos[index])
            FlutterMethods.addFileViewingRecord(videos[index])
        }
    }

    private fun playNext() {
        if (index < videos.lastIndex) {
            index += 1
            currentTime = 0
            totalTime = 0
            startPlay(index, videos[index])
            FlutterMethods.addFileViewingRecord(videos[index])
        }
    }

    private fun startPlay(index: Int, video: VideoItem) {
        val playUrl = if (video.localPath.isNullOrEmpty()) video.url else video.localPath
        videoPlayer.setUp(playUrl, false, video.name.substringBeforeLast("."))
        FlutterMethods.findVideoRecordByPath(video.remotePath) { record ->
            Debuger.printfLog("seekOnStart=${record.videoCurrentPosition}")
            videoPlayer.seekOnStart = record.videoCurrentPosition ?: 0L
            videoPlayer.startPlayLogic()
        }

        if (index == 0) {
            btnPrevious.alpha = 0.5f
        } else {
            btnPrevious.alpha = 1f
        }

        if (index == videos.lastIndex) {
            btnNext.alpha = 0.5f
        } else {
            btnNext.alpha = 1f
        }
    }

    override fun onPause() {
        videoPlayer.currentPlayer.onVideoPause()
        super.onPause()
        isPause = true
        saveCurrentTime()
    }

    private fun saveCurrentTime() {
        if (videos.isNotEmpty() && totalTime > 0) {
            val video = videos[index]
            Debuger.printfLog("save ${video.remotePath} $currentTime $totalTime")
            FlutterMethods.insertOrUpdateVideoRecord(
                video.remotePath,
                currentTime,
                totalTime,
                video.sign
            )
        }
    }

    override fun onResume() {
        videoPlayer.currentPlayer.onVideoResume(false)
        super.onResume()
        isPause = false
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isPlay) {
            videoPlayer.currentPlayer.release()
        }
        if (orientationUtils != null) orientationUtils.releaseListener()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        //如果旋转了就全屏
        if (isPlay && !isPause) {
            videoPlayer.onConfigurationChanged(this, newConfig, orientationUtils, true, true)
        }
    }


    override fun onBackPressed() {
        if (orientationUtils != null) {
            orientationUtils.backToProtVideo()
        }
        if (GSYVideoManager.backFromWindowFull(this)) {
            return
        }
        super.onBackPressed()
    }


    override fun getGSYVideoPlayer() = videoPlayer

    override fun getGSYVideoOptionBuilder(): GSYVideoOptionBuilder {
        //内置封面可参考SampleCoverVideo
        return GSYVideoOptionBuilder()
            .setCacheWithPlay(true)
            .setVideoTitle(" ")
            .setIsTouchWiget(true)
            .setRotateViewAuto(false)
            .setLockLand(false)
            .setShowFullAnimation(false)
            .setNeedLockFull(true)
            .setSeekRatio(1f)
    }

    override fun clickForFullScreen() {
    }

    override fun getDetailOrientationRotateAuto() = true
    override fun onProgress(p0: Long, p1: Long, currentTime: Long, totalTime: Long) {
        if (totalTime <= 0) {
            return
        }

        this.totalTime = totalTime
        this.currentTime = currentTime
    }
}