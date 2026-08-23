package dev.wndls.clockrhythm.rhythm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

internal class RhythmAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != RHYTHM_ALARM_ACTION) {
            return
        }
        val expectedRevision = intent.getLongExtra(EXTRA_RHYTHM_REVISION, -1)
        val expectedOccurrenceId = intent.getStringExtra(EXTRA_RHYTHM_OCCURRENCE_ID)
        if (expectedRevision <= 0 || expectedOccurrenceId.isNullOrBlank()) {
            return
        }

        val pendingResult = goAsync()
        val finished = AtomicBoolean(false)
        val finishOnce = {
            if (finished.compareAndSet(false, true)) {
                pendingResult.finish()
            }
        }
        try {
            val applicationContext = context.applicationContext
            val stateStore =
                RhythmDeliveryStateStore(applicationContext.noBackupFilesDir)
            val capability = AndroidDeliveryCapability(applicationContext)
            val coordinator =
                RhythmDeliveryCoordinator(
                    stateRepository = stateStore,
                    scheduler =
                        AndroidRhythmExactAlarmScheduler(
                            context = applicationContext,
                            capability = capability,
                        ),
                    notificationPublisher =
                        AndroidRhythmNotificationPublisher(applicationContext),
                    backgroundRequester =
                        BackgroundFlutterCoordinator(applicationContext),
                    bootCountSource =
                        AndroidRhythmBootCountSource(
                            applicationContext.contentResolver,
                        ),
                )
            coordinator.deliverAlarm(
                expectedRevision = expectedRevision,
                expectedOccurrenceId = expectedOccurrenceId,
                onBackgroundFinished = finishOnce,
            )
        } catch (_: Exception) {
            Log.e(TAG, "RHYTHM_ALARM_DELIVERY_FAILED")
            finishOnce()
        }
    }

    private companion object {
        const val TAG: String = "RhythmAlarmReceiver"
    }
}
