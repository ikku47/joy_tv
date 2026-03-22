package com.example.joy_tv

import android.os.Bundle
import com.example.joy_tv.streamengine.StreamEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.MainScope

class MainActivity : FlutterActivity() {
    private lateinit var streamEngine: StreamEngine
    private val scope = MainScope()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        streamEngine = StreamEngine(scope)
        streamEngine.setup(this, messenger, scope)
    }
}
