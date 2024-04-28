package com.github.alist.bean

import com.google.gson.annotations.SerializedName

class ExternalPlayer(
    @SerializedName("packageName")
    val packageName: String,
    @SerializedName("activity")
    val activity: String,
    @SerializedName("label")
    val label: String,
    @SerializedName("icon")
    val icon: String
)