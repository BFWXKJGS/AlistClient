package com.github.alist.utils

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

object GsonUtils {
    val gson = Gson()

    inline fun <reified K, reified V> parseMap(jsonText: String): Map<K, V> {
        val resultType =
            TypeToken.getParameterized(MutableMap::class.java, K::class.java, V::class.java)
        return gson.fromJson(jsonText, resultType) as Map<K, V>
    }

    inline fun <reified T> parseList(jsonText: String): List<T> {
        val resultType = TypeToken.getParameterized(List::class.java, T::class.java)
        return gson.fromJson(jsonText, resultType) as List<T>
    }

    inline fun <reified T> parseObject(jsonText: String): T {
        return gson.fromJson(jsonText, T::class.java)
    }

    fun toJsonString(jsonObj: Any): String {
        return gson.toJson(jsonObj)
    }
}