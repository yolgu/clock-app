package dev.wndls.clockrhythm.rhythm

internal enum class RhythmAlarmDeliveryResult {
    DELIVERED,
    SKIPPED_MISSED,
    STALE,
}

internal class StaleRhythmDeliveryRevisionException(
    message: String,
) : IllegalStateException(message)

internal class InvalidRhythmDeliveryReplacementException(
    message: String,
) : IllegalArgumentException(message)

internal data class RhythmBackgroundRefillRequest(
    val expectedRevision: Long,
    val observedAtEpochMillis: Long,
    val state: RhythmDeliveryState,
) {
    init {
        require(state.isActive) { "A background refill requires active state." }
        require(expectedRevision == state.revision) {
            "Background refill revision must match persisted state."
        }
    }

    fun toChannelMap(): Map<String, Any?> =
        RhythmDeliveryPlanChannelCodec.encodeBackgroundRequest(
            state = state,
            observedAtEpochMillis = observedAtEpochMillis,
        )
}

internal interface BackgroundRefillCompletion {
    fun complete(
        expectedRevision: Long,
        observedAtEpochMillis: Long,
        replacement: RhythmDeliveryState,
    ): Boolean

    fun failed(expectedRevision: Long)
}

internal interface BackgroundRefillRequester {
    fun requestRefill(
        request: RhythmBackgroundRefillRequest,
        completion: BackgroundRefillCompletion,
        onFinished: () -> Unit,
    )
}

internal class NoopBackgroundRefillRequester : BackgroundRefillRequester {
    override fun requestRefill(
        request: RhythmBackgroundRefillRequest,
        completion: BackgroundRefillCompletion,
        onFinished: () -> Unit,
    ) {
        completion.failed(request.expectedRevision)
        onFinished()
    }
}

internal class NoopRhythmNotificationPublisher : RhythmNotificationPublisher {
    override fun publish(occurrence: RhythmOccurrenceState) = Unit
}

internal class RhythmDeliveryCoordinator(
    private val stateRepository: RhythmDeliveryStateRepository,
    private val scheduler: RhythmExactAlarmScheduler,
    private val notificationPublisher: RhythmNotificationPublisher,
    private val backgroundRequester: BackgroundRefillRequester,
    private val timeSource: AndroidTimeSource = SystemAndroidTimeSource,
    private val bootCountSource: RhythmBootCountSource = UnknownRhythmBootCountSource,
) : BackgroundRefillCompletion {
    fun status(): RhythmDeliveryState =
        synchronized(RhythmDeliveryStateLock.monitor) {
            stateRepository.load()
        }

    fun schedule(plan: RhythmDeliveryState): RhythmDeliveryState {
        requirePrecomputedQueue(plan)
        return adoptNewerPlan(plan)
    }

    fun reconcile(plan: RhythmDeliveryState): RhythmDeliveryState {
        requirePrecomputedQueue(plan)
        return synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            if (!current.isActive) {
                throw InvalidRhythmDeliveryReplacementException(
                    "Inactive Android Rhythm delivery cannot reconcile into Running.",
                )
            }
            requireNoExplicitRecovery(current)
            requireNewerRevision(current, plan)
            adoptPlanLocked(current, plan)
        }
    }

    fun recoverExplicitly(plan: RhythmDeliveryState): RhythmDeliveryState {
        requirePrecomputedQueue(plan)
        return synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            if (!current.isActive || !current.needsRecovery) {
                throw InvalidRhythmDeliveryReplacementException(
                    "Explicit recovery requires active interrupted delivery.",
                )
            }
            requireNewerRevision(current, plan)
            adoptPlanLocked(current, plan)
        }
    }

    fun replacePayload(replacement: RhythmDeliveryState): RhythmDeliveryState =
        synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            requireNoExplicitRecovery(current)
            requireNewerRevision(current, replacement)
            requirePayloadOnlyReplacement(current, replacement)
            adoptPlanLocked(current, replacement)
        }

    fun cancel(): RhythmDeliveryState =
        synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            val nextRevision = nextRevision(current.revision)
            val inactive =
                RhythmDeliveryState.inactive(
                    revision = nextRevision,
                    requestCode = current.requestCode,
                )
            stateRepository.save(inactive)
            scheduler.cancel(current.requestCode)
            inactive
        }

    fun deliverAlarm(
        expectedRevision: Long,
        expectedOccurrenceId: String,
        onBackgroundFinished: () -> Unit,
    ): RhythmAlarmDeliveryResult {
        var deliveryResult = RhythmAlarmDeliveryResult.STALE
        val refillRequest =
            synchronized(RhythmDeliveryStateLock.monitor) {
                val current = stateRepository.load()
                val occurrence = current.currentOccurrence
                if (
                    !current.isActive ||
                    current.revision != expectedRevision ||
                    occurrence?.occurrenceId != expectedOccurrenceId
                ) {
                    null
                } else {
                    val observedAtEpochMillis = timeSource.currentTimeMillis()
                    val nextOccurrence = current.occurrences.getOrNull(1)
                    val missed =
                        nextOccurrence != null &&
                            nextOccurrence.occursAtEpochMillis <= observedAtEpochMillis
                    val afterDelivery =
                        if (missed) {
                            deliveryResult = RhythmAlarmDeliveryResult.SKIPPED_MISSED
                            current.skipOccurrencesAtOrBefore(observedAtEpochMillis)
                        } else {
                            notificationPublisher.publish(occurrence)
                            deliveryResult = RhythmAlarmDeliveryResult.DELIVERED
                            current.afterCurrentDelivery()
                        }
                    stateRepository.save(afterDelivery)
                    if (afterDelivery.currentOccurrence != null) {
                        try {
                            scheduler.scheduleEarliest(afterDelivery)
                        } catch (error: Exception) {
                            stateRepository.save(afterDelivery.markNeedsRecovery())
                            throw error
                        }
                    }
                    RhythmBackgroundRefillRequest(
                        expectedRevision = afterDelivery.revision,
                        observedAtEpochMillis = observedAtEpochMillis,
                        state = afterDelivery,
                    )
                }
            }
        if (refillRequest == null) {
            onBackgroundFinished()
            return RhythmAlarmDeliveryResult.STALE
        }
        backgroundRequester.requestRefill(
            request = refillRequest,
            completion = this,
            onFinished = onBackgroundFinished,
        )
        return deliveryResult
    }

    override fun complete(
        expectedRevision: Long,
        observedAtEpochMillis: Long,
        replacement: RhythmDeliveryState,
    ): Boolean =
        synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            if (!current.isActive || current.revision != expectedRevision) {
                return@synchronized false
            }
            requirePrecomputedQueue(replacement)
            val firstOccurrence = requireNotNull(replacement.currentOccurrence)
            if (firstOccurrence.occursAtEpochMillis <= observedAtEpochMillis) {
                throw InvalidRhythmDeliveryReplacementException(
                    "Background refill must contain only future occurrences.",
                )
            }
            requireNewerRevision(current, replacement)
            adoptPlanLocked(current, replacement)
            true
        }

    override fun failed(expectedRevision: Long) {
        synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            if (current.isActive && current.revision == expectedRevision) {
                stateRepository.save(current.markNeedsRecovery())
            }
        }
    }

    private fun adoptNewerPlan(plan: RhythmDeliveryState): RhythmDeliveryState =
        synchronized(RhythmDeliveryStateLock.monitor) {
            val current = stateRepository.load()
            requireNewerRevision(current, plan)
            adoptPlanLocked(current, plan)
        }

    private fun adoptPlanLocked(
        current: RhythmDeliveryState,
        replacement: RhythmDeliveryState,
    ): RhythmDeliveryState {
        val registeredReplacement =
            replacement
                .registeredForBoot(bootCountSource.currentBootCount())
                .clearNeedsRecovery()
        scheduler.ensureCanSchedule()
        scheduler.scheduleEarliest(registeredReplacement)
        try {
            stateRepository.save(registeredReplacement)
        } catch (error: Exception) {
            restoreAlarmAfterFailedCommit(current)
            throw error
        }
        return registeredReplacement
    }

    private fun restoreAlarmAfterFailedCommit(previous: RhythmDeliveryState) {
        try {
            if (previous.isActive) {
                scheduler.scheduleEarliest(previous)
            } else {
                scheduler.cancel(previous.requestCode)
            }
        } catch (_: Exception) {
            // The persisted previous revision remains authoritative; stale alarms are ignored.
        }
    }

    private fun requirePayloadOnlyReplacement(
        current: RhythmDeliveryState,
        replacement: RhythmDeliveryState,
    ) {
        if (!current.isActive || !replacement.isActive) {
            throw InvalidRhythmDeliveryReplacementException(
                "Payload replacement requires active delivery state.",
            )
        }
        if (current.configuration != replacement.configuration) {
            throw InvalidRhythmDeliveryReplacementException(
                "Payload replacement cannot change Rhythm configuration.",
            )
        }
        if (current.occurrences.size != replacement.occurrences.size) {
            throw InvalidRhythmDeliveryReplacementException(
                "Payload replacement cannot change the occurrence queue.",
            )
        }
        current.occurrences.zip(replacement.occurrences).forEach { (before, after) ->
            if (
                before.occurrenceId != after.occurrenceId ||
                before.kind != after.kind ||
                before.occursAtEpochMillis != after.occursAtEpochMillis ||
                before.windowStartsAtEpochMillis != after.windowStartsAtEpochMillis
            ) {
                throw InvalidRhythmDeliveryReplacementException(
                    "Payload replacement must preserve occurrence identity and timestamps.",
                )
            }
        }
    }

    private fun requireNewerRevision(
        current: RhythmDeliveryState,
        replacement: RhythmDeliveryState,
    ) {
        if (replacement.revision <= current.revision) {
            throw StaleRhythmDeliveryRevisionException(
                "Android Rhythm delivery revision ${replacement.revision} is stale.",
            )
        }
    }

    private fun requireNoExplicitRecovery(current: RhythmDeliveryState) {
        if (current.needsRecovery) {
            throw InvalidRhythmDeliveryReplacementException(
                "Android Rhythm delivery requires explicit Recovery or Start.",
            )
        }
    }

    private fun requirePrecomputedQueue(plan: RhythmDeliveryState) {
        if (!plan.isActive || plan.occurrences.size < MINIMUM_PRECOMPUTED_OCCURRENCES) {
            throw InvalidRhythmDeliveryReplacementException(
                "Android Rhythm delivery requires current plus two future occurrences.",
            )
        }
    }

    private fun nextRevision(currentRevision: Long): Long {
        if (currentRevision == Long.MAX_VALUE) {
            throw StaleRhythmDeliveryRevisionException(
                "Android Rhythm delivery revision is exhausted.",
            )
        }
        return currentRevision + 1
    }
}
