package dev.wndls.clockrhythm

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import dev.wndls.clockrhythm.rhythm.CLOCK_ROUTE
import dev.wndls.clockrhythm.rhythm.RhythmAlarmBridge

class MainActivity : FlutterActivity() {
    private var rhythmAlarmBridge: RhythmAlarmBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        rhythmAlarmBridge =
            RhythmAlarmBridge(
                activity = this,
                messenger = flutterEngine.dartExecutor.binaryMessenger,
            ).also(RhythmAlarmBridge::register)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        rhythmAlarmBridge?.dispose()
        rhythmAlarmBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        rhythmAlarmBridge?.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults,
        )
    }

    override fun onResume(): Unit {
        super.onResume()
        rhythmAlarmBridge?.auditForeground()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (RhythmAlarmBridge.isClockActivation(intent)) {
            rhythmAlarmBridge?.notifyClockActivation()
        }
    }

    override fun getInitialRoute(): String? =
        if (RhythmAlarmBridge.isClockActivation(intent)) {
            CLOCK_ROUTE
        } else {
            super.getInitialRoute()
        }
}
