package com.github.alist.widget

import android.content.Context
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatImageView

class VisibleChangeListenerImageView(context: Context, attrs: AttributeSet?) :
    AppCompatImageView(context, attrs) {
    var onVisibleChangeListener: (Int) -> Unit = {}

    override fun setVisibility(visibility: Int) {
        super.setVisibility(visibility)
        onVisibleChangeListener(visibility)
    }
}