package com.github.alist.widget;

import android.content.Context;
import android.graphics.Outline;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewOutlineProvider;

import androidx.annotation.NonNull;
import androidx.core.view.GestureDetectorCompat;

import com.github.alist.client.R;
import com.shuyu.gsyvideoplayer.video.NormalGSYVideoPlayer;
import com.shuyu.gsyvideoplayer.video.base.GSYBaseVideoPlayer;

public class AlistClientVideoPlayer extends NormalGSYVideoPlayer {
    private GestureDetectorCompat gestureDetector;
    private VideoPlayerGestureListener gestureListener;
    protected View btnPrevious;
    protected View btnNext;
    protected View btnRewind;
    protected View btnFfwd;
    private View tvPlayingAtDoubleSpeed;
    protected boolean isEnableSeek;
    private boolean isLongPressing;

    public AlistClientVideoPlayer(Context context, Boolean fullFlag) {
        super(context, fullFlag);
    }

    public AlistClientVideoPlayer(Context context) {
        super(context);
    }

    public AlistClientVideoPlayer(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    protected void init(Context context) {
        super.init(context);
        gestureListener = new VideoPlayerGestureListener();
        gestureDetector = new GestureDetectorCompat(context, gestureListener);
        gestureDetector.setIsLongpressEnabled(true);
        tvPlayingAtDoubleSpeed = findViewById(R.id.tv_playing_at_double_speed);
        btnPrevious = findViewById(R.id.btn_previous);
        btnNext = findViewById(R.id.btn_next);
        btnRewind = findViewById(R.id.btn_rewind);
        btnFfwd = findViewById(R.id.btn_ffwd);
        btnRewind.setVisibility(View.INVISIBLE);
        btnFfwd.setVisibility(View.INVISIBLE);
        btnRewind.setOnClickListener(v -> {
            if (getDuration() > 0L) {
                long targetPosition =
                        Math.max(0, getGSYVideoManager().getCurrentPosition() - 10000);
                getGSYVideoManager().seekTo(targetPosition);
            }
        });
        btnFfwd.setOnClickListener(v -> {
            long duration = getDuration();
            if (duration > 0L) {
                long targetPosition = Math.min(duration, getGSYVideoManager().getCurrentPosition() + 10000);
                getGSYVideoManager().seekTo(targetPosition);
            }
        });
        tvPlayingAtDoubleSpeed.setOutlineProvider(new ViewOutlineProvider() {
            @Override
            public void getOutline(View view, Outline outline) {
                int radius = dp2Px(2);
                outline.setRoundRect(0, 0, view.getWidth(), view.getHeight(), radius);
            }
        });
        tvPlayingAtDoubleSpeed.setClipToOutline(true);
    }

    private int dp2Px(int dp) {
        DisplayMetrics displayMetrics = getContext().getResources().getDisplayMetrics();
        return Math.round(displayMetrics.density * dp);
    }

    public View getBtnPrevious() {
        return btnPrevious;
    }

    public View getBtnNext() {
        return btnNext;
    }

    public View getBtnRewind() {
        return btnRewind;
    }

    public View getBtnFfwd() {
        return btnFfwd;
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        if (v.getId() == R.id.surface_container && this.mIfCurrentIsFullscreen && !this.mLockCurScreen) {
            if ((event.getActionMasked() == MotionEvent.ACTION_UP || event.getActionMasked() == MotionEvent.ACTION_CANCEL) && isLongPressing) {
                isLongPressing = false;
                tvPlayingAtDoubleSpeed.setVisibility(View.INVISIBLE);
                setSpeedPlaying(1, false);
            }
            gestureDetector.onTouchEvent(event);
        }
        return super.onTouch(v, event);
    }

    @Override
    public void onPrepared() {
        super.onPrepared();
        isEnableSeek = getDuration() > 0L;
        if (!isEnableSeek) {
            btnRewind.setVisibility(View.GONE);
            btnFfwd.setVisibility(View.GONE);
        }
    }

    protected void setCenterButtonsVisibility(int visibility) {
        btnPrevious.setVisibility(visibility);
        btnNext.setVisibility(visibility);
        if (isEnableSeek) {
            btnRewind.setVisibility(visibility);
            btnFfwd.setVisibility(visibility);
        }
    }

    @Override
    protected void hideAllWidget() {
        super.hideAllWidget();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToNormal() {
        super.changeUiToNormal();
        setCenterButtonsVisibility(View.VISIBLE);
    }

    @Override
    protected void changeUiToPreparingShow() {
        super.changeUiToPreparingShow();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToPlayingShow() {
        super.changeUiToPlayingShow();
        if (!this.mLockCurScreen || !this.mNeedLockFull) {
            setCenterButtonsVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void changeUiToPauseShow() {
        super.changeUiToPauseShow();
        if (!this.mLockCurScreen || !this.mNeedLockFull) {
            setCenterButtonsVisibility(View.INVISIBLE);
            btnPrevious.setVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void changeUiToPlayingBufferingShow() {
        super.changeUiToPlayingBufferingShow();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToCompleteShow() {
        super.changeUiToCompleteShow();
        setCenterButtonsVisibility(View.VISIBLE);
    }

    @Override
    protected void changeUiToError() {
        super.changeUiToError();
        setCenterButtonsVisibility(View.VISIBLE);
    }

    @Override
    protected void changeUiToPrepareingClear() {
        super.changeUiToPrepareingClear();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToPlayingBufferingClear() {
        super.changeUiToPlayingBufferingClear();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToClear() {
        super.changeUiToClear();
        setCenterButtonsVisibility(View.INVISIBLE);
    }

    @Override
    protected void changeUiToCompleteClear() {
        super.changeUiToCompleteClear();
        setCenterButtonsVisibility(View.VISIBLE);
    }

    @Override
    public GSYBaseVideoPlayer startWindowFullscreen(Context context, boolean actionBar, boolean statusBar) {
        AlistClientVideoPlayer videoPlayer = (AlistClientVideoPlayer) super.startWindowFullscreen(context, actionBar, statusBar);
        if (videoPlayer != null) {
            videoPlayer.isEnableSeek = this.isEnableSeek;

            if (isEnableSeek && videoPlayer.getStartButton() != null && videoPlayer.getStartButton().getVisibility() == View.VISIBLE) {
                videoPlayer.setCenterButtonsVisibility(View.VISIBLE);
            }
        }
        return videoPlayer;
    }

    @Override
    public int getLayoutId() {
        return R.layout.video_layout_alist_client;
    }

    private class VideoPlayerGestureListener extends GestureDetector.SimpleOnGestureListener {

        @Override
        public boolean onDown(@NonNull MotionEvent e) {
            return true;
        }

        @Override
        public boolean onSingleTapUp(@NonNull MotionEvent e) {
            performClick();
            return true;
        }

        @Override
        public void onLongPress(@NonNull MotionEvent e) {
            isLongPressing = true;
            if (getDuration() > 0) {
                setSpeedPlaying(2, false);
                tvPlayingAtDoubleSpeed.setVisibility(View.VISIBLE);
            }
        }
    }
}
