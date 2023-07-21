package com.github.alist.plugin

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AlistPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.github.alist.client.plugin")
        context = binding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAppInstalled" -> {
                val packageName: String? = call.argument("packageName")
                if (packageName.isNullOrEmpty()) {
                    result.error("INVALID_PACKAGE_NAME", "The package name is invalid", null)
                    return
                }

                try {
                    val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
                    val isInstalled = packageInfo.applicationInfo.enabled
                    result.success(isInstalled)
                } catch (exc: PackageManager.NameNotFoundException) {
                    result.success(false)
                }
            }

            "launchApp" -> {
                val packageName: String? = call.argument("packageName")
                val uri: String? = call.argument("uri")
                if (packageName.isNullOrEmpty()) {
                    result.error("INVALID_PACKAGE_NAME", "The package name is invalid", null)
                    return
                }
                if (uri.isNullOrEmpty()) {
                    try {
                        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                        context.startActivity(intent)
                        result.success(true)
                    } catch (exc: PackageManager.NameNotFoundException) {
                        result.success(false)
                    }
                } else {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            data = Uri.parse(uri)
                            setPackage(packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (exc: PackageManager.NameNotFoundException) {
                        result.success(false)
                    }
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }
}