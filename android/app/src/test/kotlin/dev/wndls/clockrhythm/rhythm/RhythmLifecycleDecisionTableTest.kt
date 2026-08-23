package dev.wndls.clockrhythm.rhythm

class RhythmLifecycleDecisionTableTest {
    @Test
    fun `maps only the declared Android lifecycle actions`() {
        val expectedReasons =
            RhythmLifecycleReason.entries.filter { reason ->
                reason != RhythmLifecycleReason.FOREGROUND
            }

        expectedReasons.forEach { reason ->
            assertEquals(
                reason,
                RhythmLifecycleReason.fromIntentAction(reason.intentAction),
            )
        }
        assertNull(RhythmLifecycleReason.fromIntentAction(null))
        assertNull(
            RhythmLifecycleReason.fromIntentAction(
                "dev.wndls.clockrhythm.UNKNOWN",
            ),
        )
    }

    @Test
    fun `keeps an inactive intent inactive for every lifecycle reason`() {
        RhythmLifecycleReason.entries.forEach { reason ->
            val decision =
                RhythmLifecycleDecisionTable.decide(
                    reason = reason,
                    input = activeInput(isActive = false),
                )

            assertEquals(RhythmRecoveryDisposition.INACTIVE, decision.disposition)
            assertNull(decision.cause)
        }
    }

    @Test
    fun `reports running only when foreground registration is current and valid`() {
        val decision =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.FOREGROUND,
                input = activeInput(),
            )

        assertEquals(RhythmRecoveryDisposition.RUNNING, decision.disposition)
        assertNull(decision.cause)
    }

    @Test
    fun `requires explicit recovery when foreground registration is missing`() {
        val decision =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.FOREGROUND,
                input = activeInput(registrationPresent = false),
            )

        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.REGISTRATION_MISSING,
            decision.cause,
        )
    }

    @Test
    fun `requires explicit recovery when a required permission is absent`() {
        val decision =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.FOREGROUND,
                input = activeInput(capabilityGranted = false),
            )

        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.PERMISSION_LOST,
            decision.cause,
        )
    }

    @Test
    fun `reconciles a real reboot but rejects a delayed same-boot signal`() {
        val reboot =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.BOOT_COMPLETED,
                input = activeInput(registeredBootCount = 41, currentBootCount = 42),
            )
        val delayedAfterForceStop =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.BOOT_COMPLETED,
                input = activeInput(registrationPresent = false),
            )

        assertEquals(
            RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY,
            reboot.disposition,
        )
        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            delayedAfterForceStop.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.REGISTRATION_MISSING,
            delayedAfterForceStop.cause,
        )
    }

    @Test
    fun `reconciles package and wall-clock changes for an active permitted intent`() {
        val automaticReasons =
            listOf(
                RhythmLifecycleReason.PACKAGE_REPLACED,
                RhythmLifecycleReason.TIME_SET,
                RhythmLifecycleReason.TIMEZONE_CHANGED,
            )

        automaticReasons.forEach { reason ->
            val decision =
                RhythmLifecycleDecisionTable.decide(
                    reason = reason,
                    input = activeInput(),
                )
            assertEquals(
                RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY,
                decision.disposition,
            )
        }
    }

    @Test
    fun `exact alarm permission grant never resumes an active intent`() {
        val decision =
            RhythmLifecycleDecisionTable.decide(
                reason = RhythmLifecycleReason.EXACT_ALARM_PERMISSION_GRANTED,
                input = activeInput(),
            )

        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.PERMISSION_LOST,
            decision.cause,
        )
    }

    @Test
    fun `persisted user-mediated recovery blocks later automatic signals`() {
        val causes =
            listOf(
                RhythmDeliveryRecoveryCause.PERMISSION_LOST,
                RhythmDeliveryRecoveryCause.REGISTRATION_MISSING,
            )

        causes.forEach { cause ->
            val decision =
                RhythmLifecycleDecisionTable.decide(
                    reason = RhythmLifecycleReason.TIMEZONE_CHANGED,
                    input = activeInput(persistedRecoveryCause = cause),
                )
            assertEquals(
                RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
                decision.disposition,
            )
            assertEquals(cause, decision.cause)
        }
    }

    private fun activeInput(
        isActive: Boolean = true,
        capabilityGranted: Boolean = true,
        registrationPresent: Boolean = true,
        registeredBootCount: Int? = 41,
        currentBootCount: Int? = 41,
        persistedRecoveryCause: RhythmDeliveryRecoveryCause? = null,
    ): RhythmLifecycleDecisionInput =
        RhythmLifecycleDecisionInput(
            isActive = isActive,
            capabilityGranted = capabilityGranted,
            registrationPresent = registrationPresent,
            registeredBootCount = registeredBootCount,
            currentBootCount = currentBootCount,
            persistedRecoveryCause = persistedRecoveryCause,
        )
}
