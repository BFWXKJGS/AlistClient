package com.github.alist.activity

import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.view.View
import android.view.ViewGroup.MarginLayoutParams
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.isInvisible
import androidx.core.view.isVisible
import androidx.core.view.updateLayoutParams
import com.github.alist.bean.VideoItem
import com.github.alist.client.BuildConfig
import com.github.alist.client.R
import com.github.alist.utils.FlutterMethods
import com.github.alist.utils.GsonUtils
import com.github.alist.widget.AlistClientVideoPlayer
import com.shuyu.gsyvideoplayer.GSYVideoManager
import com.shuyu.gsyvideoplayer.builder.GSYVideoOptionBuilder
import com.shuyu.gsyvideoplayer.listener.GSYSampleCallBack
import com.shuyu.gsyvideoplayer.listener.GSYVideoProgressListener
import com.shuyu.gsyvideoplayer.player.IjkPlayerManager
import com.shuyu.gsyvideoplayer.player.PlayerFactory
import com.shuyu.gsyvideoplayer.utils.Debuger
import com.shuyu.gsyvideoplayer.utils.OrientationUtils
import com.shuyu.gsyvideoplayer.video.NormalGSYVideoPlayer
import com.shuyu.gsyvideoplayer.video.base.GSYVideoView
import tv.danmaku.ijk.media.exo2.Exo2PlayerManager
import kotlin.math.abs

class PlayerActivity : AppCompatActivity(), GSYVideoProgressListener {
    private lateinit var playerWrapper: PlayerWrapper
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
    private lateinit var gsyVideoPlayer: AlistClientVideoPlayer
    private lateinit var orientationUtils: OrientationUtils
    private var isPause = false
    private var isPlay = true

    private val messageRecordWatchTime = 1
    private val handler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            if (msg.what == messageRecordWatchTime) {
                saveCurrentTime()
                // 每30s记录一次播放进度
                sendEmptyMessageDelayed(messageRecordWatchTime, 30 * 1000)
            }
        }
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

    private fun initViews() {
        gsyVideoPlayer = findViewById(R.id.video_player)
        playerWrapper = PlayerWrapper(gsyVideoPlayer)
        playerWrapper.initViews()
        gsyVideoPlayer.setGSYVideoProgressListener(this)
        orientationUtils = OrientationUtils(this, gsyVideoPlayer)
        orientationUtils.isEnable = false

        val gsyVideoOption = GSYVideoOptionBuilder()
        gsyVideoOption
            .setIsTouchWiget(true)
            .setRotateViewAuto(true)
            .setLockLand(false)
            .setAutoFullWithSize(true)
            .setShowFullAnimation(false)
            .setMapHeadData(headers)
            .setNeedLockFull(true)
            .setVideoAllCallBack(object : GSYSampleCallBack() {
                override fun onPrepared(url: String, vararg objects: Any) {
                    super.onPrepared(url, *objects)
                    //开始播放了才能旋转和全屏
                    orientationUtils.isEnable = true
                    isPlay = true
                    handler.removeMessages(messageRecordWatchTime)
                    // 延时 30 秒记录一次播放进度
                    handler.sendEmptyMessageDelayed(messageRecordWatchTime, 30 * 1000)
                }

                override fun onComplete(url: String?, vararg objects: Any?) {
                    super.onComplete(url, *objects)
                    handler.removeMessages(messageRecordWatchTime)
                    if (totalTime > 0 && abs(totalTime - currentTime) <= 1000) {
                        handler.sendEmptyMessage(messageRecordWatchTime)
                    }
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
                    Debuger.printfError("***** onEnterFullscreen **** ${playerWrapper.btnPrevious.isVisible}")
                }

                override fun onQuitFullscreen(url: String, vararg objects: Any) {
                    super.onQuitFullscreen(url, *objects)
                    Debuger.printfError("***** onQuitFullscreen **** " + objects[0]) //title
                    Debuger.printfError("***** onQuitFullscreen **** " + objects[1]) //当前非全屏player
                    orientationUtils.backToProtVideo()
                    gsyVideoPlayer.post {
                        windowInsetsControllerCompat.show(WindowInsetsCompat.Type.statusBars())
                        windowInsetsControllerCompat.show(WindowInsetsCompat.Type.navigationBars())
                    }
                    playerWrapper.btnBack.setOnClickListener {
                        finish()
                    }
                }

                override fun onPlayError(url: String?, vararg objects: Any?) {
                    super.onPlayError(url, *objects)
                    if (totalTime > 0) {
                        gsyVideoPlayer.seekOnStart = currentTime
                        gsyVideoPlayer.currentPlayer.seekOnStart = currentTime
                    }
                    Debuger.printfError("***** onPlayError ****")
                }
            }).setLockClickListener { _, lock ->
                orientationUtils.isEnable = !lock
            }.build(gsyVideoPlayer)

        gsyVideoPlayer.fullscreenButton.setOnClickListener { //直接横屏
            orientationUtils.resolveByClick()
            gsyVideoPlayer.startWindowFullscreen(this@PlayerActivity, true, true)?.let {
                PlayerWrapper(it as AlistClientVideoPlayer).initViews()
            }
        }

        ViewCompat.setOnApplyWindowInsetsListener(gsyVideoPlayer) { _, insets ->
            val navigationBars = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val statusBars = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            playerWrapper.layoutTop.updateLayoutParams<MarginLayoutParams> {
                topMargin = statusBars.top
            }
            playerWrapper.layoutBottom.updateLayoutParams<MarginLayoutParams> {
                bottomMargin = navigationBars.bottom
            }
            playerWrapper.bottomProgressbar.updateLayoutParams<MarginLayoutParams> {
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
        gsyVideoPlayer.currentPlayer.setUp(playUrl, false, video.name.substringBeforeLast("."))
        FlutterMethods.findVideoRecordByPath(video.remotePath) { record ->
            Debuger.printfLog("seekOnStart=${record.videoCurrentPosition}")
            gsyVideoPlayer.currentPlayer.seekOnStart = record.videoCurrentPosition ?: 0L
            gsyVideoPlayer.currentPlayer.startPlayLogic()
        }
        val currentPlayer = playerWrapper.videoPlayer.currentPlayer as NormalGSYVideoPlayer
        playerWrapper.tvTitle.text = video.name.substringBeforeLast(".")
        currentPlayer.titleTextView.text = video.name.substringBeforeLast(".")

        if (index == 0) {
            playerWrapper.btnPrevious.alpha = 0.5f
            currentPlayer.findViewById<View>(R.id.btn_previous).alpha = 0.5f
        } else {
            playerWrapper.btnPrevious.alpha = 1f
            currentPlayer.findViewById<View>(R.id.btn_previous).alpha = 1f
        }

        if (index == videos.lastIndex) {
            playerWrapper.btnNext.alpha = 0.5f
            currentPlayer.findViewById<View>(R.id.btn_next).alpha = 0.5f
        } else {
            playerWrapper.btnNext.alpha = 1f
            currentPlayer.findViewById<View>(R.id.btn_next).alpha = 1f
        }
    }

    override fun onPause() {
        gsyVideoPlayer.currentPlayer.onVideoPause()
        super.onPause()
        isPause = true
        handler.removeMessages(messageRecordWatchTime)
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
        gsyVideoPlayer.currentPlayer.onVideoResume(false)
        super.onResume()
        isPause = false
        if (gsyVideoPlayer.currentPlayer.currentState == GSYVideoView.CURRENT_STATE_PLAYING
            || gsyVideoPlayer.currentPlayer.currentState == GSYVideoView.CURRENT_STATE_PLAYING_BUFFERING_START
            || gsyVideoPlayer.currentPlayer.currentState == GSYVideoView.CURRENT_STATE_PREPAREING
        ) {
            handler.sendEmptyMessageDelayed(messageRecordWatchTime, 10)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isPlay) {
            gsyVideoPlayer.currentPlayer.release()
        }
        orientationUtils.releaseListener()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        //如果旋转了就全屏
        if (isPlay && !isPause) {
            gsyVideoPlayer.onConfigurationChanged(this, newConfig, orientationUtils, true, true)
        }
    }


    override fun onBackPressed() {
        orientationUtils.backToProtVideo()
        if (GSYVideoManager.backFromWindowFull(this)) {
            return
        }
        super.onBackPressed()
    }


    override fun onProgress(p0: Long, p1: Long, currentTime: Long, totalTime: Long) {
        if (totalTime <= 0) {
            return
        }

        this.totalTime = totalTime
        this.currentTime = currentTime
    }

    inner class PlayerWrapper(val videoPlayer: AlistClientVideoPlayer) {
        lateinit var btnPrevious: View
            private set
        lateinit var btnNext: View
            private set
        lateinit var layoutTop: View
            private set
        lateinit var layoutBottom: View
            private set
        lateinit var bottomProgressbar: View
            private set
        lateinit var tvTitle: TextView
            private set
        lateinit var btnBack: View
            private set
        private lateinit var btnPlayStart: View

        fun initViews() {
            findViews()
            videoPlayer.btnPrevious.alpha = if (index > 0) 1f else 0.5f
            videoPlayer.btnNext.alpha = if (index >= videos.lastIndex) 0.5f else 1f

            btnPrevious.setOnClickListener {
                saveCurrentTime()
                playPrevious()
            }
            btnNext.setOnClickListener {
                saveCurrentTime()
                playNext()
            }
            videoPlayer.setOnLongClickListener {

                true
            }
        }

        private fun findViews() {
            layoutTop = videoPlayer.findViewById(R.id.layout_top)
            layoutBottom = videoPlayer.findViewById(R.id.layout_bottom)
            bottomProgressbar = videoPlayer.findViewById(R.id.bottom_progressbar)
            tvTitle = videoPlayer.findViewById(R.id.title)
            btnBack = videoPlayer.findViewById(R.id.back)
            btnPrevious = videoPlayer.findViewById(R.id.btn_previous)
            btnNext = videoPlayer.findViewById(R.id.btn_next)
            btnPlayStart = videoPlayer.findViewById(R.id.start)
        }
    }
}