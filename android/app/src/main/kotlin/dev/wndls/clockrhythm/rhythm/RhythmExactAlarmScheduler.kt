package dev.wndls.clockrhythm.rhythm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

internal const val RHYTHM_ALARM_ACTION: String =
    "dev.wndls.clockrhythm.action.DELIVER_RHYTHM_EVENT"
internal const val EXTRA_RHYTHM_REVISION: String = "rhythmRevision"
internal const val EXTRA_RHYTHM_OCCURRENCE_ID: String = "rhythmOccurrenceId"

internal interface AndroidTimeSource {
    fun currentTimeMillis(): Long
}

internal object SystemAndroidTimeSource : AndroidTimeSource {
    override fun currentTimeMillis(): Long = System.currentTimeMillis()
}

internal interface RhythmExactAlarmScheduler {
    fun ensureCanSchedule()

    fun scheduleEarliest(state: RhythmDeliveryState)

    fun cancel(requestCode: Int)
}

internal fun interface RhythmAlarmRegistrationInspector {
    fun hasRegistration(requestCode: Int): Boolean
}

internal class AndroidRhythmAlarmRegistrationInspector(
    private val context: Context,
) : RhythmAlarmRegistrationInspector {
    override fun hasRegistration(requestCode: Int): Boolean =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, RhythmAlarmReceiver::class.java).setAction(
                RHYTHM_ALARM_ACTION,
            ),
            PendingIntent.FLAG_NO_CREATE or
                PendingIntent.FLAG_IMMUTABLE or
                PendingIntent.FLAG_ONE_SHOT,
        ) != null
}

internal class AndroidRhythmExactAlarmScheduler(
    private val context: Context,
    private val capability: AndroidDeliveryCapability,
    private val timeSource: AndroidTimeSource = SystemAndroidTimeSource,
) : RhythmExactAlarmScheduler {
    override fun ensureCanSchedule() {
        val failure = capability.status().failure
        if (failure != null) {
            throw AndroidDeliveryPermissionException(failure)
        }
    }

    override fun scheduleEarliest(state: RhythmDeliveryState) {
        check(state.isActive) { "Only an active Rhythm state can schedule an alarm." }
        val occurrence = requireNotNull(state.currentOccurrence)
        ensureCanSchedule()
        if (occurrence.occursAtEpochMillis <= timeSource.currentTimeMillis()) {
            throw StaleRhythmOccurrenceException(
                "Refusing to register a missed Rhythm occurrence.",
            )
        }
        try {
            alarmManager().setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                occurrence.occursAtEpochMillis,
                pendingAlarmIntent(
                    requestCode = state.requestCode,
                    revision = state.revision,
                    occurrenceId = occurrence.occurrenceId,
                ),
            )
        } catch (error: SecurityException) {
            val failure = capability.status().failure
            if (failure != null) {
                throw AndroidDeliveryPermissionException(failure)
            }
            throw error
        }
    }

    override fun cancel(requestCode: Int) {
        val pendingIntent =
            PendingIntent.getBroadcast(
                context,
                requestCode,
                alarmIntent(),
                PendingIntent.FLAG_NO_CREATE or
                    PendingIntent.FLAG_IMMUTABLE or
                    PendingIntent.FLAG_ONE_SHOT,
            ) ?: return
        alarmManager().cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun pendingAlarmIntent(
        requestCode: Int,
        revision: Long,
        occurrenceId: String,
    ): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            alarmIntent().apply {
                putExtra(EXTRA_RHYTHM_REVISION, revision)
                putExtra(EXTRA_RHYTHM_OCCURRENCE_ID, occurrenceId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE or
                PendingIntent.FLAG_ONE_SHOT,
        )

    private fun alarmIntent(): Intent =
        Intent(context, RhythmAlarmReceiver::class.java).setAction(RHYTHM_ALARM_ACTION)

    private fun alarmManager(): AlarmManager =
        context.getSystemService(AlarmManager::class.java)
}

internal class StaleRhythmOccurrenceException(
    message: String,
) : IllegalStateException(message)
