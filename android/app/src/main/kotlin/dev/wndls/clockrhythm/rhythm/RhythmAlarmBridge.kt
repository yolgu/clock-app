package dev.wndls.clockrhythm.rhythm

import android.app.Activity
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal object RhythmAlarmChannelContract {
    const val CHANNEL_NAME: String = "dev.wndls.clockrhythm/rhythm_delivery"
    const val STATUS: String = "status"
    const val CAPABILITY_STATUS: String = "capabilityStatus"
    const val REQUEST_START_CAPABILITY: String = "requestStartCapability"
    const val OPEN_SETTINGS: String = "openSettings"
    const val SCHEDULE: String = "schedule"
    const val CANCEL: String = "cancel"
    const val REPLACE_PAYLOAD: String = "replacePayload"
    const val RECONCILE: String = "reconcile"
    const val AUDIT_RECOVERY: String = "auditRecovery"
    const val RECOVER_EXPLICITLY: String = "recoverExplicitly"
    const val ACTIVATE_CLOCK: String = "activateClock"
    const val BACKGROUND_READY: String = "backgroundReady"
    const val COMPLETE_BACKGROUND_REFILL: String = "completeBackgroundRefill"
    const val BACKGROUND_REFILL_FAILED: String = "backgroundRefillFailed"
    const val LIFECYCLE_READY: String = "lifecycleReady"
    const val COMPLETE_LIFECYCLE_RECONCILE: String =
        "completeLifecycleReconcile"
    const val LIFECYCLE_RECONCILE_FAILED: String =
        "lifecycleReconcileFailed"
}

internal class RhythmAlarmBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, RhythmAlarmChannelContract.CHANNEL_NAME)
    private val stateStore = RhythmDeliveryStateStore(activity.noBackupFilesDir)
    private val capability = AndroidDeliveryCapability(activity.applicationContext)
    private val scheduler =
        AndroidRhythmExactAlarmScheduler(
            context = activity.applicationContext,
            capability = capability,
        )
    private val bootCountSource =
        AndroidRhythmBootCountSource(activity.contentResolver)
    private val coordinator =
        RhythmDeliveryCoordinator(
            stateRepository = stateStore,
            scheduler = scheduler,
            notificationPublisher = NoopRhythmNotificationPublisher(),
            backgroundRequester = NoopBackgroundRefillRequester(),
            bootCountSource = bootCountSource,
        )
    private val startupAudit =
        RhythmStartupAudit(
            stateRepository = stateStore,
            scheduler = scheduler,
            registrationInspector =
                AndroidRhythmAlarmRegistrationInspector(
                    activity.applicationContext,
                ),
            capabilityReader =
                RhythmDeliveryCapabilityReader { capability.status().isGranted },
            bootCountSource = bootCountSource,
        )
    private var pendingPermissionResult: MethodChannel.Result? = null

    fun register() {
        channel.setMethodCallHandler(::handleMethodCall)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingPermissionResult?.error(
            "channelUnavailable",
            "Android Rhythm activity was disposed.",
            null,
        )
        pendingPermissionResult = null
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        _permissions: Array<out String>,
        _grantResults: IntArray,
    ): Boolean {
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) {
            return false
        }
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        result.success(capability.status().toChannelMap())
        return true
    }

    fun notifyClockActivation() {
        channel.invokeMethod(
            RhythmAlarmChannelContract.ACTIVATE_CLOCK,
            mapOf("route" to CLOCK_ROUTE),
        )
    }

    fun auditForeground(): Unit {
        try {
            startupAudit.audit(RhythmLifecycleReason.FOREGROUND)
        } catch (_: Exception) {
            Log.e(TAG, "RHYTHM_FOREGROUND_AUDIT_FAILED")
        }
    }

    private fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                RhythmAlarmChannelContract.STATUS ->
                    result.success(deliveryStatus())
                RhythmAlarmChannelContract.CAPABILITY_STATUS ->
                    result.success(capability.status().toChannelMap())
                RhythmAlarmChannelContract.REQUEST_START_CAPABILITY ->
                    requestStartCapability(result)
                RhythmAlarmChannelContract.OPEN_SETTINGS -> {
                    val arguments = requireMap(call.arguments, "openSettings")
                    val failure = requireStartFailure(arguments["failure"])
                    capability.openSettings(activity, failure)
                    result.success(null)
                }
                RhythmAlarmChannelContract.SCHEDULE -> {
                    val plan = RhythmDeliveryPlanChannelCodec.decodePlan(call.arguments)
                    result.success(statusAfter(coordinator.schedule(plan)))
                }
                RhythmAlarmChannelContract.CANCEL ->
                    result.success(statusAfter(coordinator.cancel()))
                RhythmAlarmChannelContract.REPLACE_PAYLOAD -> {
                    val replacement =
                        RhythmDeliveryPlanChannelCodec.decodePlan(call.arguments)
                    result.success(statusAfter(coordinator.replacePayload(replacement)))
                }
                RhythmAlarmChannelContract.RECONCILE -> {
                    val replacement =
                        RhythmDeliveryPlanChannelCodec.decodePlan(call.arguments)
                    result.success(statusAfter(coordinator.reconcile(replacement)))
                }
                RhythmAlarmChannelContract.AUDIT_RECOVERY ->
                    result.success(
                        RhythmDeliveryPlanChannelCodec.encodeStartupAudit(
                            startupAudit.audit(RhythmLifecycleReason.FOREGROUND),
                        ),
                    )
                RhythmAlarmChannelContract.RECOVER_EXPLICITLY -> {
                    val audit = startupAudit.audit(RhythmLifecycleReason.FOREGROUND)
                    if (
                        audit.decision.disposition !=
                        RhythmRecoveryDisposition.NEEDS_USER_RECOVERY
                    ) {
                        throw InvalidRhythmDeliveryReplacementException(
                            "Explicit recovery requires a user-recovery state.",
                        )
                    }
                    val replacement =
                        RhythmDeliveryPlanChannelCodec.decodePlan(call.arguments)
                    coordinator.recoverExplicitly(replacement)
                    result.success(
                        RhythmDeliveryPlanChannelCodec.encodeStartupAudit(
                            startupAudit.audit(RhythmLifecycleReason.FOREGROUND),
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            reportError(result, error)
        }
    }

    private fun requestStartCapability(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error(
                "channelUnavailable",
                "A notification permission request is already active.",
                null,
            )
            return
        }
        if (!capability.needsNotificationPermissionRequest()) {
            result.success(capability.status().toChannelMap())
            return
        }
        pendingPermissionResult = result
        try {
            capability.requestNotificationPermission(activity)
        } catch (error: Exception) {
            pendingPermissionResult = null
            throw error
        }
    }

    private fun deliveryStatus(): Map<String, Any?> =
        RhythmDeliveryPlanChannelCodec.encodeStatus(coordinator.status())

    private fun statusAfter(state: RhythmDeliveryState): Map<String, Any?> =
        RhythmDeliveryPlanChannelCodec.encodeStatus(state)

    private fun reportError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val code =
            when (error) {
                is AndroidDeliveryPermissionException ->
                    when (error.failure) {
                        AndroidDeliveryCapabilityFailure.NOTIFICATION_PERMISSION ->
                            "notificationPermissionDenied"
                        AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION ->
                            "exactAlarmPermissionDenied"
                        AndroidDeliveryCapabilityFailure
                            .NOTIFICATION_AND_EXACT_ALARM_PERMISSION ->
                            "notificationAndExactAlarmPermissionDenied"
                    }
                is StaleRhythmDeliveryRevisionException -> "staleRevision"
                is MalformedRhythmDeliveryPlanException -> "invalidPayload"
                is MalformedRhythmDeliveryStateException -> "stateUnavailable"
                is RhythmDeliveryStatePersistenceException -> "stateUnavailable"
                is InvalidRhythmDeliveryReplacementException -> "invalidPayload"
                else -> "schedulingFailed"
            }
        val message =
            when (code) {
                "notificationPermissionDenied",
                "exactAlarmPermissionDenied",
                "notificationAndExactAlarmPermissionDenied",
                -> "Android Rhythm delivery permission is not granted."
                "staleRevision" -> "Android Rhythm delivery revision is stale."
                "invalidPayload" -> "Android Rhythm delivery payload is invalid."
                "stateUnavailable" -> "Android Rhythm delivery state is unavailable."
                else -> "Android Rhythm delivery scheduling failed."
            }
        result.error(code, message, null)
    }

    companion object {
        fun isClockActivation(intent: Intent?): Boolean =
            intent?.action == ACTION_OPEN_CLOCK &&
                intent.getStringExtra(EXTRA_OPEN_CLOCK_ROUTE) == CLOCK_ROUTE

        private const val TAG: String = "RhythmAlarmBridge"
    }

    private fun requireStartFailure(value: Any?): String {
        val failure = requireText(value, "failure")
        if (
            failure !in
            setOf(
                "notificationPermission",
                "exactAlarmPermission",
                "notificationAndExactAlarmPermission",
                "deliveryUnavailable",
            )
        ) {
            throw MalformedRhythmDeliveryPlanException(
                "Unsupported Android Rhythm settings failure.",
            )
        }
        return failure
    }

}
