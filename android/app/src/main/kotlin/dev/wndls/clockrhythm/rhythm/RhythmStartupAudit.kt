package dev.wndls.clockrhythm.rhythm

import android.app.AlarmManager
import android.content.ContentResolver
import android.content.Intent
import android.provider.Settings

internal enum class RhythmLifecycleReason(
    val wireName: String,
    val intentAction: String?,
) {
    FOREGROUND("foreground", null),
    BOOT_COMPLETED("bootCompleted", Intent.ACTION_BOOT_COMPLETED),
    PACKAGE_REPLACED("packageReplaced", Intent.ACTION_MY_PACKAGE_REPLACED),
    TIME_SET("timeSet", Intent.ACTION_TIME_CHANGED),
    TIMEZONE_CHANGED("timezoneChanged", Intent.ACTION_TIMEZONE_CHANGED),
    EXACT_ALARM_PERMISSION_GRANTED(
        "exactAlarmPermissionGranted",
        AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED,
    ),
    ;

    companion object {
        fun fromIntentAction(action: String?): RhythmLifecycleReason? =
            entries.firstOrNull { reason ->
                reason.intentAction != null && reason.intentAction == action
            }
    }
}

internal enum class RhythmRecoveryDisposition(
    val wireName: String,
) {
    INACTIVE("inactive"),
    RUNNING("running"),
    RECONCILE_AUTOMATICALLY("reconcileAutomatically"),
    NEEDS_USER_RECOVERY("needsUserRecovery"),
}

internal data class RhythmLifecycleDecisionInput(
    val isActive: Boolean,
    val capabilityGranted: Boolean,
    val registrationPresent: Boolean,
    val registeredBootCount: Int?,
    val currentBootCount: Int?,
    val persistedRecoveryCause: RhythmDeliveryRecoveryCause?,
)

internal data class RhythmLifecycleDecision(
    val disposition: RhythmRecoveryDisposition,
    val cause: RhythmDeliveryRecoveryCause?,
)

internal object RhythmLifecycleDecisionTable {
    fun decide(
        reason: RhythmLifecycleReason,
        input: RhythmLifecycleDecisionInput,
    ): RhythmLifecycleDecision {
        if (!input.isActive) {
            return RhythmLifecycleDecision(
                disposition = RhythmRecoveryDisposition.INACTIVE,
                cause = null,
            )
        }
        val persistedCause = input.persistedRecoveryCause
        if (persistedCause?.requiresExplicitUserRecovery == true) {
            return needsUserRecovery(persistedCause)
        }
        if (!input.capabilityGranted) {
            return needsUserRecovery(RhythmDeliveryRecoveryCause.PERMISSION_LOST)
        }
        if (reason == RhythmLifecycleReason.EXACT_ALARM_PERMISSION_GRANTED) {
            return needsUserRecovery(RhythmDeliveryRecoveryCause.PERMISSION_LOST)
        }
        if (reason == RhythmLifecycleReason.FOREGROUND) {
            return foregroundDecision(input)
        }
        if (reason == RhythmLifecycleReason.BOOT_COMPLETED) {
            val isNewBoot =
                input.registeredBootCount != null &&
                    input.currentBootCount != null &&
                    input.registeredBootCount != input.currentBootCount
            return if (isNewBoot) {
                reconcileAutomatically()
            } else {
                needsUserRecovery(RhythmDeliveryRecoveryCause.REGISTRATION_MISSING)
            }
        }
        return reconcileAutomatically()
    }

    private fun foregroundDecision(
        input: RhythmLifecycleDecisionInput,
    ): RhythmLifecycleDecision {
        val registrationMatchesBoot =
            input.registeredBootCount != null &&
                input.currentBootCount != null &&
                input.registeredBootCount == input.currentBootCount
        if (!input.registrationPresent || !registrationMatchesBoot) {
            return needsUserRecovery(RhythmDeliveryRecoveryCause.REGISTRATION_MISSING)
        }
        return RhythmLifecycleDecision(
            disposition = RhythmRecoveryDisposition.RUNNING,
            cause = input.persistedRecoveryCause,
        )
    }

    private fun reconcileAutomatically(): RhythmLifecycleDecision =
        RhythmLifecycleDecision(
            disposition = RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY,
            cause = null,
        )

    private fun needsUserRecovery(
        cause: RhythmDeliveryRecoveryCause,
    ): RhythmLifecycleDecision =
        RhythmLifecycleDecision(
            disposition = RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            cause = cause,
        )
}

internal fun interface RhythmDeliveryCapabilityReader {
    fun isGranted(): Boolean
}

internal fun interface RhythmBootCountSource {
    fun currentBootCount(): Int?
}

internal object UnknownRhythmBootCountSource : RhythmBootCountSource {
    override fun currentBootCount(): Int? = null
}

internal class AndroidRhythmBootCountSource(
    private val contentResolver: ContentResolver,
) : RhythmBootCountSource {
    override fun currentBootCount(): Int? {
        val bootCount =
            Settings.Global.getInt(
                contentResolver,
                Settings.Global.BOOT_COUNT,
                UNKNOWN_BOOT_COUNT,
            )
        return bootCount.takeIf { value -> value >= 0 }
    }

    private companion object {
        const val UNKNOWN_BOOT_COUNT: Int = -1
    }
}

internal data class RhythmStartupAuditResult(
    val lifecycleReason: RhythmLifecycleReason,
    val decision: RhythmLifecycleDecision,
    val state: RhythmDeliveryState,
    val observedAtEpochMillis: Long,
)

internal class RhythmStartupAudit(
    private val stateRepository: RhythmDeliveryStateRepository,
    private val scheduler: RhythmExactAlarmScheduler,
    private val registrationInspector: RhythmAlarmRegistrationInspector,
    private val capabilityReader: RhythmDeliveryCapabilityReader,
    private val bootCountSource: RhythmBootCountSource,
    private val timeSource: AndroidTimeSource = SystemAndroidTimeSource,
) {
    fun audit(reason: RhythmLifecycleReason): RhythmStartupAuditResult =
        synchronized(RhythmDeliveryStateLock.monitor) {
            val observedAtEpochMillis = timeSource.currentTimeMillis()
            val current = stateRepository.load()
            val registrationPresent =
                current.isActive &&
                    current.currentOccurrence != null &&
                    registrationInspector.hasRegistration(current.requestCode)
            val decision =
                RhythmLifecycleDecisionTable.decide(
                    reason = reason,
                    input =
                        RhythmLifecycleDecisionInput(
                            isActive = current.isActive,
                            capabilityGranted =
                                !current.isActive || capabilityReader.isGranted(),
                            registrationPresent = registrationPresent,
                            registeredBootCount = current.registeredBootCount,
                            currentBootCount =
                                if (current.isActive) {
                                    bootCountSource.currentBootCount()
                                } else {
                                    null
                                },
                            persistedRecoveryCause = current.recoveryCause,
                        ),
                )
            val auditedState =
                applyDecision(
                    current = current,
                    decision = decision,
                    registrationPresent = registrationPresent,
                )
            RhythmStartupAuditResult(
                lifecycleReason = reason,
                decision = decision,
                state = auditedState,
                observedAtEpochMillis = observedAtEpochMillis,
            )
        }

    private fun applyDecision(
        current: RhythmDeliveryState,
        decision: RhythmLifecycleDecision,
        registrationPresent: Boolean,
    ): RhythmDeliveryState =
        when (decision.disposition) {
            RhythmRecoveryDisposition.INACTIVE,
            RhythmRecoveryDisposition.RUNNING,
            -> current
            RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY ->
                interruptDeliveryForRecovery(
                    current,
                    RhythmDeliveryRecoveryCause.AUTOMATIC_RECONCILE_FAILED,
                )
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY ->
                interruptDeliveryForRecovery(
                    current,
                    requireNotNull(decision.cause),
                    registrationPresent = registrationPresent,
                )
        }

    private fun interruptDeliveryForRecovery(
        current: RhythmDeliveryState,
        cause: RhythmDeliveryRecoveryCause,
        registrationPresent: Boolean = true,
    ): RhythmDeliveryState {
        if (current.recoveryCause == cause && !registrationPresent) {
            return current
        }
        scheduler.cancel(current.requestCode)
        val interrupted = current.interruptForRecovery(cause)
        stateRepository.save(interrupted)
        return interrupted
    }
}
