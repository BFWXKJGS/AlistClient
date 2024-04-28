package com.github.alist.bean

class VideoItem(
    val name: String,
    val localPath: String?,
    val remotePath: String,
    val sign: String?,
    val provider: String?,
    val thumb: String?,
    val url: String,
    val modifiedMilliseconds: String?,
    val size: String?
)