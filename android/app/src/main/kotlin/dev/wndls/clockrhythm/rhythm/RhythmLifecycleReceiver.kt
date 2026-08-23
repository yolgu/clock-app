package dev.wndls.clockrhythm.rhythm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

internal class RhythmLifecycleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent): Unit {
        val reason = RhythmLifecycleReason.fromIntentAction(intent.action) ?: return
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
            val scheduler =
                AndroidRhythmExactAlarmScheduler(
                    context = applicationContext,
                    capability = capability,
                )
            val bootCountSource =
                AndroidRhythmBootCountSource(
                    applicationContext.contentResolver,
                )
            val deliveryCoordinator =
                RhythmDeliveryCoordinator(
                    stateRepository = stateStore,
                    scheduler = scheduler,
                    notificationPublisher = NoopRhythmNotificationPublisher(),
                    backgroundRequester = NoopBackgroundRefillRequester(),
                    bootCountSource = bootCountSource,
                )
            val audit =
                RhythmStartupAudit(
                    stateRepository = stateStore,
                    scheduler = scheduler,
                    registrationInspector =
                        AndroidRhythmAlarmRegistrationInspector(
                            applicationContext,
                        ),
                    capabilityReader =
                        RhythmDeliveryCapabilityReader {
                            capability.status().isGranted
                        },
                    bootCountSource = bootCountSource,
                ).audit(reason)
            if (
                audit.decision.disposition ==
                RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY
            ) {
                RhythmLifecycleFlutterCoordinator(
                    context = applicationContext,
                    deliveryCoordinator = deliveryCoordinator,
                ).requestReconciliation(audit, finishOnce)
            } else {
                finishOnce()
            }
        } catch (_: Exception) {
            Log.e(TAG, "RHYTHM_LIFECYCLE_AUDIT_FAILED")
            finishOnce()
        }
    }

    private companion object {
        const val TAG: String = "RhythmLifecycleReceiver"
    }
}
