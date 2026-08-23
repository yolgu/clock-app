package dev.wndls.clockrhythm.rhythm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import dev.wndls.clockrhythm.BuildConfig
import dev.wndls.clockrhythm.MainActivity

internal val RHYTHM_NOTIFICATION_CHANNEL_ID: String =
    BuildConfig.RHYTHM_NOTIFICATION_CHANNEL_ID
internal const val RHYTHM_NOTIFICATION_TAG: String = "clock-rhythm-event"
internal const val RHYTHM_NOTIFICATION_ID: Int = 41_003
internal const val RHYTHM_NOTIFICATION_CONTENT_REQUEST_CODE: Int = 41_004
internal const val ACTION_OPEN_CLOCK: String =
    "dev.wndls.clockrhythm.action.OPEN_CLOCK"
internal const val EXTRA_OPEN_CLOCK_ROUTE: String = "openClockRoute"
internal const val CLOCK_ROUTE: String = "/clock"

internal interface RhythmNotificationPublisher {
    fun publish(occurrence: RhythmOccurrenceState)
}

internal class AndroidRhythmNotificationPublisher(
    private val context: Context,
) : RhythmNotificationPublisher {
    override fun publish(occurrence: RhythmOccurrenceState) {
        createNotificationChannel()
        notificationManager().notify(
            RHYTHM_NOTIFICATION_TAG,
            RHYTHM_NOTIFICATION_ID,
            buildNotification(occurrence),
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val applicationLabel =
            context.applicationInfo.loadLabel(context.packageManager)
        val channel =
            NotificationChannel(
                RHYTHM_NOTIFICATION_CHANNEL_ID,
                applicationLabel,
                NotificationManager.IMPORTANCE_DEFAULT,
            )
        notificationManager().createNotificationChannel(channel)
    }

    private fun buildNotification(occurrence: RhythmOccurrenceState): Notification {
        val builder = NotificationCompat.Builder(context, RHYTHM_NOTIFICATION_CHANNEL_ID)
        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(occurrence.payload.title)
            .setContentText(occurrence.payload.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(occurrence.payload.body))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(clockContentIntent())
            .setAutoCancel(true)
            .setOnlyAlertOnce(false)
            .setSilent(occurrence.muted)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && occurrence.muted) {
            builder.setSound(null)
        } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            builder.setDefaults(Notification.DEFAULT_SOUND)
        }
        return builder.build()
    }

    private fun clockContentIntent(): PendingIntent =
        PendingIntent.getActivity(
            context,
            RHYTHM_NOTIFICATION_CONTENT_REQUEST_CODE,
            Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_CLOCK
                putExtra(EXTRA_OPEN_CLOCK_ROUTE, CLOCK_ROUTE)
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun notificationManager(): NotificationManager =
        context.getSystemService(NotificationManager::class.java)
}
