package dev.wndls.clockrhythm.rhythm

class RhythmDeliveryCoordinatorTest {
    @Test
    fun `replaces a newer payload revision and rejects a stale retry`() {
        val repository = InMemoryStateRepository(deliveryState(revision = 7))
        val scheduler = RecordingScheduler()
        val coordinator = coordinator(repository, scheduler)
        val replacement =
            deliveryState(revision = 8).replacePresentation(
                RhythmNotificationPresentationState(
                    focusEnded = RhythmNotificationPayload("집중 종료", "휴식할 시간입니다."),
                    restEnded = RhythmNotificationPayload("휴식 종료", "집중할 시간입니다."),
                    muted = true,
                ),
            )

        coordinator.replacePayload(replacement)

        assertEquals(replacement, repository.state)
        assertEquals(replacement, scheduler.scheduled.single())
        assertFailsWith<StaleRhythmDeliveryRevisionException> {
            coordinator.replacePayload(replacement)
        }
    }

    @Test
    fun `permission denial leaves native state and registration untouched`() {
        val original = RhythmDeliveryState.inactive(revision = 3)
        val repository = InMemoryStateRepository(original)
        val scheduler = DeniedScheduler()
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = scheduler,
                notificationPublisher = RecordingPublisher(),
                backgroundRequester = RecordingBackgroundRequester(),
                timeSource = FixedTimeSource(500),
            )

        assertFailsWith<AndroidDeliveryPermissionException> {
            coordinator.schedule(deliveryState(revision = 4))
        }

        assertEquals(original, repository.state)
        assertTrue(scheduler.scheduled.isEmpty())
    }

    @Test
    fun `reconcile cannot activate an inactive native session`() {
        val original = RhythmDeliveryState.inactive(revision = 5)
        val repository = InMemoryStateRepository(original)
        val coordinator = coordinator(repository, RecordingScheduler())

        assertFailsWith<InvalidRhythmDeliveryReplacementException> {
            coordinator.reconcile(deliveryState(revision = 6))
        }

        assertEquals(original, repository.state)
    }

    @Test
    fun `automatic replacements cannot clear an explicit recovery marker`() {
        val original =
            deliveryState(revision = 6).copy(
                recoveryCause = RhythmDeliveryRecoveryCause.PERMISSION_LOST,
            )
        val repository = InMemoryStateRepository(original)
        val scheduler = RecordingScheduler()
        val coordinator = coordinator(repository, scheduler)

        assertFailsWith<InvalidRhythmDeliveryReplacementException> {
            coordinator.reconcile(deliveryState(revision = 7))
        }
        assertFailsWith<InvalidRhythmDeliveryReplacementException> {
            coordinator.replacePayload(deliveryState(revision = 7))
        }

        assertEquals(original, repository.state)
        assertTrue(scheduler.scheduled.isEmpty())
    }

    @Test
    fun `explicit recovery adopts a newer plan and clears its marker`() {
        val original =
            deliveryState(revision = 8).copy(
                recoveryCause = RhythmDeliveryRecoveryCause.REGISTRATION_MISSING,
            )
        val repository = InMemoryStateRepository(original)
        val scheduler = RecordingScheduler()
        val coordinator = coordinator(repository, scheduler)
        val replacement = deliveryState(revision = 9)

        val recovered = coordinator.recoverExplicitly(replacement)

        assertEquals(replacement, recovered)
        assertEquals(replacement, repository.state)
        assertEquals(listOf(replacement), scheduler.scheduled)
    }

    @Test
    fun `publishes current then arms next then requests refill`() {
        val calls = mutableListOf<String>()
        val initial = deliveryState(revision = 11)
        val repository = InMemoryStateRepository(initial)
        val scheduler = RecordingScheduler(calls)
        val publisher = RecordingPublisher(calls)
        val background = RecordingBackgroundRequester(calls)
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = scheduler,
                notificationPublisher = publisher,
                backgroundRequester = background,
                timeSource = FixedTimeSource(1_500),
            )

        val result =
            coordinator.deliverAlarm(
                expectedRevision = initial.revision,
                expectedOccurrenceId = initial.currentOccurrence!!.occurrenceId,
                onBackgroundFinished = {},
            )

        assertEquals(RhythmAlarmDeliveryResult.DELIVERED, result)
        assertEquals(listOf("current", "next", "refill"), calls)
        assertEquals(2, repository.state.occurrences.size)
        assertEquals(
            initial.occurrences[1].occurrenceId,
            repository.state.currentOccurrence!!.occurrenceId,
        )
    }

    @Test
    fun `ignores stale revision and occurrence alarm events`() {
        val calls = mutableListOf<String>()
        val initial = deliveryState(revision = 21)
        val repository = InMemoryStateRepository(initial)
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = RecordingScheduler(calls),
                notificationPublisher = RecordingPublisher(calls),
                backgroundRequester = RecordingBackgroundRequester(calls),
                timeSource = FixedTimeSource(1_500),
            )

        val staleRevision =
            coordinator.deliverAlarm(
                expectedRevision = 20,
                expectedOccurrenceId = initial.currentOccurrence!!.occurrenceId,
                onBackgroundFinished = {},
            )
        val staleOccurrence =
            coordinator.deliverAlarm(
                expectedRevision = 21,
                expectedOccurrenceId = "different-occurrence",
                onBackgroundFinished = {},
            )

        assertEquals(RhythmAlarmDeliveryResult.STALE, staleRevision)
        assertEquals(RhythmAlarmDeliveryResult.STALE, staleOccurrence)
        assertTrue(calls.isEmpty())
        assertEquals(initial, repository.state)
    }

    @Test
    fun `skips boundaries superseded before a delayed alarm arrives`() {
        val calls = mutableListOf<String>()
        val initial = deliveryState(revision = 31)
        val repository = InMemoryStateRepository(initial)
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = RecordingScheduler(calls),
                notificationPublisher = RecordingPublisher(calls),
                backgroundRequester = RecordingBackgroundRequester(calls),
                timeSource = FixedTimeSource(2_500),
            )

        val result =
            coordinator.deliverAlarm(
                expectedRevision = 31,
                expectedOccurrenceId = initial.currentOccurrence!!.occurrenceId,
                onBackgroundFinished = {},
            )

        assertEquals(RhythmAlarmDeliveryResult.SKIPPED_MISSED, result)
        assertEquals(listOf("next", "refill"), calls)
        assertEquals("3000:focusEnds", repository.state.currentOccurrence!!.occurrenceId)
    }

    @Test
    fun `requests recovery refill after delivering the final queued occurrence`() {
        val calls = mutableListOf<String>()
        val initial =
            deliveryState(revision = 41).copy(
                occurrences = deliveryState(revision = 41).occurrences.take(1),
            )
        val repository = InMemoryStateRepository(initial)
        val coordinator =
            RhythmDeliveryCoordinator(
                stateRepository = repository,
                scheduler = RecordingScheduler(calls),
                notificationPublisher = RecordingPublisher(calls),
                backgroundRequester = RecordingBackgroundRequester(calls),
                timeSource = FixedTimeSource(500),
            )

        val result =
            coordinator.deliverAlarm(
                expectedRevision = 41,
                expectedOccurrenceId = initial.currentOccurrence!!.occurrenceId,
                onBackgroundFinished = {},
            )

        assertEquals(RhythmAlarmDeliveryResult.DELIVERED, result)
        assertEquals(listOf("current", "refill"), calls)
        assertTrue(repository.state.isActive)
        assertTrue(repository.state.needsRecovery)
        assertTrue(repository.state.occurrences.isEmpty())
    }

    @Test
    fun `marks only the matching active revision when refill fails`() {
        val initial = deliveryState(revision = 51)
        val repository = InMemoryStateRepository(initial)
        val coordinator = coordinator(repository, RecordingScheduler())

        coordinator.failed(expectedRevision = 50)
        assertEquals(initial, repository.state)

        coordinator.failed(expectedRevision = 51)
        assertTrue(repository.state.needsRecovery)
        assertEquals(initial.occurrences, repository.state.occurrences)
    }

    private fun coordinator(
        repository: InMemoryStateRepository,
        scheduler: RecordingScheduler,
    ): RhythmDeliveryCoordinator =
        RhythmDeliveryCoordinator(
            stateRepository = repository,
            scheduler = scheduler,
            notificationPublisher = RecordingPublisher(),
            backgroundRequester = RecordingBackgroundRequester(),
            timeSource = FixedTimeSource(1_500),
        )
}

private class InMemoryStateRepository(
    var state: RhythmDeliveryState,
) : RhythmDeliveryStateRepository {
    override fun load(): RhythmDeliveryState = state

    override fun save(state: RhythmDeliveryState) {
        this.state = state
    }
}

private class RecordingScheduler(
    private val calls: MutableList<String>? = null,
) : RhythmExactAlarmScheduler {
    val scheduled = mutableListOf<RhythmDeliveryState>()

    override fun ensureCanSchedule() = Unit

    override fun scheduleEarliest(state: RhythmDeliveryState) {
        calls?.add("next")
        scheduled.add(state)
    }

    override fun cancel(requestCode: Int) = Unit
}

private class DeniedScheduler : RhythmExactAlarmScheduler {
    val scheduled = mutableListOf<RhythmDeliveryState>()

    override fun ensureCanSchedule() {
        throw AndroidDeliveryPermissionException(
            AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION,
        )
    }

    override fun scheduleEarliest(state: RhythmDeliveryState) {
        scheduled.add(state)
    }

    override fun cancel(requestCode: Int) = Unit
}

private class RecordingPublisher(
    private val calls: MutableList<String>? = null,
) : RhythmNotificationPublisher {
    override fun publish(occurrence: RhythmOccurrenceState) {
        calls?.add("current")
    }
}

private class RecordingBackgroundRequester(
    private val calls: MutableList<String>? = null,
) : BackgroundRefillRequester {
    override fun requestRefill(
        request: RhythmBackgroundRefillRequest,
        completion: BackgroundRefillCompletion,
        onFinished: () -> Unit,
    ) {
        calls?.add("refill")
        onFinished()
    }
}

private class FixedTimeSource(
    private val epochMillis: Long,
) : AndroidTimeSource {
    override fun currentTimeMillis(): Long = epochMillis
}

private fun RhythmDeliveryState.replacePresentation(
    replacement: RhythmNotificationPresentationState,
): RhythmDeliveryState =
    RhythmDeliveryState.active(
        revision = revision,
        requestCode = requestCode,
        registrationId = registrationId!!,
        configuration = configuration!!,
        presentation = replacement,
        occurrences =
            occurrences.map { occurrence ->
                val payload =
                    when (occurrence.kind) {
                        RhythmEventKindState.FOCUS_ENDS -> replacement.focusEnded
                        RhythmEventKindState.REST_ENDS -> replacement.restEnded
                    }
                occurrence.copy(payload = payload, muted = replacement.muted)
            },
    )
