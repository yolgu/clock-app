package dev.wndls.clockrhythm.rhythm

class RhythmStartupAuditTest {
    @Test
    fun `foreground audit preserves a current revisioned registration`() {
        val original = deliveryState(revision = 61).registeredForBoot(9)
        val repository = AuditStateRepository(original)
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler)

        val result = audit.audit(RhythmLifecycleReason.FOREGROUND)

        assertEquals(RhythmRecoveryDisposition.RUNNING, result.decision.disposition)
        assertEquals(original, result.state)
        assertTrue(scheduler.cancelledRequestCodes.isEmpty())
    }

    @Test
    fun `permission loss cancels registration and records user recovery`() {
        val repository =
            AuditStateRepository(deliveryState(revision = 62).registeredForBoot(9))
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler, capabilityGranted = false)

        val result = audit.audit(RhythmLifecycleReason.FOREGROUND)

        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            result.decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.PERMISSION_LOST,
            repository.state.recoveryCause,
        )
        assertEquals(listOf(41_001), scheduler.cancelledRequestCodes)
    }

    @Test
    fun `reboot audit interrupts stale registration before headless reconcile`() {
        val repository =
            AuditStateRepository(deliveryState(revision = 63).registeredForBoot(8))
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler)

        val result = audit.audit(RhythmLifecycleReason.BOOT_COMPLETED)

        assertEquals(
            RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY,
            result.decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.AUTOMATIC_RECONCILE_FAILED,
            repository.state.recoveryCause,
        )
        assertEquals(listOf(41_001), scheduler.cancelledRequestCodes)
    }

    @Test
    fun `permission grant records user recovery without scheduling`() {
        val repository =
            AuditStateRepository(deliveryState(revision = 64).registeredForBoot(9))
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler)

        val result =
            audit.audit(
                RhythmLifecycleReason.EXACT_ALARM_PERMISSION_GRANTED,
            )

        assertEquals(
            RhythmRecoveryDisposition.NEEDS_USER_RECOVERY,
            result.decision.disposition,
        )
        assertEquals(
            RhythmDeliveryRecoveryCause.PERMISSION_LOST,
            repository.state.recoveryCause,
        )
        assertTrue(scheduler.scheduled.isEmpty())
    }

    @Test
    fun `repeated foreground audit keeps an existing user recovery revision stable`() {
        val repository =
            AuditStateRepository(deliveryState(revision = 65).registeredForBoot(9))
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler, capabilityGranted = false)

        val first = audit.audit(RhythmLifecycleReason.FOREGROUND)
        val second = audit.audit(RhythmLifecycleReason.FOREGROUND)

        assertEquals(66L, first.state.revision)
        assertEquals(first.state, second.state)
        assertEquals(listOf(41_001), scheduler.cancelledRequestCodes)
    }

    @Test
    fun `lifecycle interruption invalidates an in-flight older refill revision`() {
        val repository =
            AuditStateRepository(deliveryState(revision = 70).registeredForBoot(9))
        val scheduler = AuditScheduler()
        val audit = auditor(repository, scheduler)
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = scheduler,
                notificationPublisher = NoopRhythmNotificationPublisher(),
                backgroundRequester = NoopBackgroundRefillRequester(),
                timeSource = AuditTimeSource(500),
                bootCountSource = RhythmBootCountSource { 9 },
            )

        audit.audit(RhythmLifecycleReason.TIME_SET)
        val adopted =
            coordinator.complete(
                expectedRevision = 70,
                observedAtEpochMillis = 500,
                replacement = deliveryState(revision = 71),
            )

        assertFalse(adopted)
        assertEquals(71L, repository.state.revision)
        assertEquals(
            RhythmDeliveryRecoveryCause.AUTOMATIC_RECONCILE_FAILED,
            repository.state.recoveryCause,
        )
    }

    private fun auditor(
        repository: AuditStateRepository,
        scheduler: AuditScheduler,
        capabilityGranted: Boolean = true,
    ): RhythmStartupAudit =
        RhythmStartupAudit(
            stateRepository = repository,
            scheduler = scheduler,
            registrationInspector =
                RhythmAlarmRegistrationInspector {
                    scheduler.registrationPresent
                },
            capabilityReader =
                RhythmDeliveryCapabilityReader { capabilityGranted },
            bootCountSource = RhythmBootCountSource { 9 },
            timeSource = AuditTimeSource(500),
        )
}

private class AuditStateRepository(
    var state: RhythmDeliveryState,
) : RhythmDeliveryStateRepository {
    override fun load(): RhythmDeliveryState = state

    override fun save(state: RhythmDeliveryState) {
        this.state = state
    }
}

private class AuditScheduler : RhythmExactAlarmScheduler {
    val scheduled = mutableListOf<RhythmDeliveryState>()
    val cancelledRequestCodes = mutableListOf<Int>()
    var registrationPresent: Boolean = true

    override fun ensureCanSchedule() = Unit

    override fun scheduleEarliest(state: RhythmDeliveryState) {
        scheduled.add(state)
    }

    override fun cancel(requestCode: Int) {
        cancelledRequestCodes.add(requestCode)
        registrationPresent = false
    }
}

private class AuditTimeSource(
    private val epochMillis: Long,
) : AndroidTimeSource {
    override fun currentTimeMillis(): Long = epochMillis
}
