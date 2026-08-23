package dev.wndls.clockrhythm.rhythm

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.net.toUri

internal const val NOTIFICATION_PERMISSION_REQUEST_CODE: Int = 41_002

internal enum class AndroidDeliveryCapabilityFailure(
    val wireName: String,
) {
    NOTIFICATION_PERMISSION("notificationPermission"),
    EXACT_ALARM_PERMISSION("exactAlarmPermission"),
    NOTIFICATION_AND_EXACT_ALARM_PERMISSION(
        "notificationAndExactAlarmPermission",
    ),
}

internal data class AndroidDeliveryCapabilityStatus(
    val sdkInt: Int,
    val notificationGranted: Boolean,
    val exactAlarmGranted: Boolean,
    val failure: AndroidDeliveryCapabilityFailure?,
) {
    val isGranted: Boolean
        get() = failure == null

    fun toChannelMap(): Map<String, Any?> =
        mapOf(
            "sdkInt" to sdkInt,
            "notificationGranted" to notificationGranted,
            "exactAlarmGranted" to exactAlarmGranted,
            "failure" to failure?.wireName,
        )
}

internal object AndroidDeliveryCapabilityPolicy {
    fun evaluate(
        sdkInt: Int,
        notificationGranted: Boolean,
        exactAlarmGranted: Boolean,
    ): AndroidDeliveryCapabilityStatus {
        val requiresExactAlarmAccess = sdkInt >= Build.VERSION_CODES.S
        val effectiveNotificationGranted = notificationGranted
        val effectiveExactAlarmGranted = !requiresExactAlarmAccess || exactAlarmGranted
        val failure =
            when {
                !effectiveNotificationGranted && !effectiveExactAlarmGranted ->
                    AndroidDeliveryCapabilityFailure
                        .NOTIFICATION_AND_EXACT_ALARM_PERMISSION
                !effectiveNotificationGranted ->
                    AndroidDeliveryCapabilityFailure.NOTIFICATION_PERMISSION
                !effectiveExactAlarmGranted ->
                    AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION
                else -> null
            }
        return AndroidDeliveryCapabilityStatus(
            sdkInt = sdkInt,
            notificationGranted = effectiveNotificationGranted,
            exactAlarmGranted = effectiveExactAlarmGranted,
            failure = failure,
        )
    }
}

internal class AndroidDeliveryCapability(
    private val context: Context,
) {
    fun status(): AndroidDeliveryCapabilityStatus {
        val sdkInt = Build.VERSION.SDK_INT
        val notificationGranted =
            hasNotificationRuntimePermission() &&
                notificationManager().areNotificationsEnabled() &&
                isRhythmNotificationChannelEnabled()
        val exactAlarmGranted =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager().canScheduleExactAlarms()
            } else {
                true
            }
        return AndroidDeliveryCapabilityPolicy.evaluate(
            sdkInt = sdkInt,
            notificationGranted = notificationGranted,
            exactAlarmGranted = exactAlarmGranted,
        )
    }

    fun needsNotificationPermissionRequest(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED

    fun requestNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST_CODE,
            )
        }
    }

    fun openSettings(
        activity: Activity,
        requestedFailure: String,
    ) {
        val intent =
            when (requestedFailure) {
                AndroidDeliveryCapabilityFailure.NOTIFICATION_PERMISSION.wireName ->
                    notificationSettingsIntent()
                AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION.wireName ->
                    exactAlarmSettingsIntent()
                AndroidDeliveryCapabilityFailure
                    .NOTIFICATION_AND_EXACT_ALARM_PERMISSION.wireName ->
                    combinedFailureSettingsIntent()
                else -> applicationDetailsIntent()
            }
        activity.startActivity(intent)
    }

    private fun combinedFailureSettingsIntent(): Intent {
        val status = status()
        return when {
            !status.notificationGranted -> notificationSettingsIntent()
            !status.exactAlarmGranted -> exactAlarmSettingsIntent()
            else -> applicationDetailsIntent()
        }
    }

    private fun exactAlarmSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                "package:${context.packageName}".toUri(),
            )
        } else {
            applicationDetailsIntent()
        }

    private fun notificationSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            }
        } else {
            applicationDetailsIntent()
        }

    private fun applicationDetailsIntent(): Intent =
        Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            "package:${context.packageName}".toUri(),
        )

    private fun alarmManager(): AlarmManager =
        context.getSystemService(AlarmManager::class.java)

    private fun notificationManager(): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    private fun hasNotificationRuntimePermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

    private fun isRhythmNotificationChannelEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return true
        }
        val channel =
            notificationManager().getNotificationChannel(RHYTHM_NOTIFICATION_CHANNEL_ID)
                ?: return true
        return channel.importance != NotificationManager.IMPORTANCE_NONE
    }
}

internal class AndroidDeliveryPermissionException(
    val failure: AndroidDeliveryCapabilityFailure,
) : SecurityException("Android Rhythm delivery capability is not granted.")
