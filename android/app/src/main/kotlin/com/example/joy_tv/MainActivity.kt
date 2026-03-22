package com.example.joy_tv

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import com.example.joy_tv.streamengine.StreamEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope

class MainActivity : FlutterActivity() {
    private lateinit var streamEngine: StreamEngine
    private val scope = MainScope()
    private val deviceChannelName = "com.example.joy_tv.device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        streamEngine = StreamEngine(scope)
        streamEngine.setup(this, messenger, scope)

        MethodChannel(messenger, deviceChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "is_tv_device" -> result.success(isTvDevice())
                else -> result.notImplemented()
            }
        }
    }

    private fun isTvDevice(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        val isTelevisionMode = uiModeManager?.currentModeType == android.content.res.Configuration.UI_MODE_TYPE_TELEVISION
        val hasLeanback = packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
        return isTelevisionMode || hasLeanback
    }
}
