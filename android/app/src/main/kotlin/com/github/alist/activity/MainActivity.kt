package com.github.alist.activity

import com.github.alist.plugin.AlistPlugin
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

class MainActivity : AudioServiceFragmentActivity() {
    private lateinit var coroutineScope: CoroutineScope

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        coroutineScope = MainScope()
        flutterEngine.plugins.add(AlistPlugin(this, coroutineScope))
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        super.onDestroy()
    }
}
