package dev.wndls.clockrhythm.rhythm

import android.system.ErrnoException
import android.system.Os
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

internal const val RHYTHM_DELIVERY_SCHEMA_VERSION: Int = 1
internal const val RHYTHM_ALARM_REQUEST_CODE: Int = 41_001
internal const val MINIMUM_PRECOMPUTED_OCCURRENCES: Int = 3
private const val RHYTHM_DELIVERY_STATE_SCHEMA_VERSION: Int = 2
private const val LEGACY_RHYTHM_DELIVERY_STATE_SCHEMA_VERSION: Int = 1
private const val STATE_FILE_NAME: String = "rhythm-delivery-state.bin"
private const val STATE_MAGIC: Int = 0x43524859
private const val MAXIMUM_QUEUE_SIZE: Int = 64
private const val MAXIMUM_IDENTIFIER_LENGTH: Int = 256
private const val MAXIMUM_TITLE_LENGTH: Int = 512
private const val MAXIMUM_BODY_LENGTH: Int = 4_096

internal object RhythmDeliveryStateLock {
    val monitor: Any = Any()
}

internal enum class RhythmEventKindState(
    val wireName: String,
) {
    FOCUS_ENDS("focusEnds"),
    REST_ENDS("restEnds"),
    ;

    companion object {
        fun parse(value: String): RhythmEventKindState =
            entries.firstOrNull { it.wireName == value }
                ?: throw MalformedRhythmDeliveryStateException(
                    "Unsupported Rhythm Event kind: $value",
                )
    }
}

internal data class RhythmNotificationPayload(
    val title: String,
    val body: String,
) {
    init {
        requireBoundedText(title, "title", MAXIMUM_TITLE_LENGTH)
        requireBoundedText(body, "body", MAXIMUM_BODY_LENGTH)
    }
}

internal data class RhythmConfigurationState(
    val focusMinutes: Int,
    val restMinutes: Int,
    val dailyStart: String,
    val dailyEnd: String,
) {
    init {
        require(focusMinutes in 1..180) { "focusMinutes must be between 1 and 180." }
        require(restMinutes in 1..60) { "restMinutes must be between 1 and 60." }
        requireClockTime(dailyStart, "dailyStart")
        requireClockTime(dailyEnd, "dailyEnd")
        require(dailyStart != dailyEnd) { "Daily Rhythm start and end must differ." }
    }
}

internal data class RhythmNotificationPresentationState(
    val focusEnded: RhythmNotificationPayload,
    val restEnded: RhythmNotificationPayload,
    val muted: Boolean,
)

internal data class RhythmOccurrenceState(
    val occurrenceId: String,
    val kind: RhythmEventKindState,
    val occursAtEpochMillis: Long,
    val windowStartsAtEpochMillis: Long,
    val payload: RhythmNotificationPayload,
    val muted: Boolean,
) {
    init {
        requireBoundedText(occurrenceId, "occurrenceId", MAXIMUM_IDENTIFIER_LENGTH)
        require(occursAtEpochMillis > windowStartsAtEpochMillis) {
            "occursAtEpochMillis must be after windowStartsAtEpochMillis."
        }
    }
}

internal enum class RhythmDeliveryRecoveryCause(
    val wireName: String,
) {
    BACKGROUND_REFILL_FAILED("deliveryInterrupted"),
    PERMISSION_LOST("permissionLost"),
    REGISTRATION_MISSING("registrationMissing"),
    AUTOMATIC_RECONCILE_FAILED("automaticReconcileFailed"),
    ;

    val requiresExplicitUserRecovery: Boolean
        get() = this == PERMISSION_LOST || this == REGISTRATION_MISSING

    companion object {
        fun parse(value: String): RhythmDeliveryRecoveryCause =
            entries.firstOrNull { it.wireName == value }
                ?: throw MalformedRhythmDeliveryStateException(
                    "Unsupported Android Rhythm recovery cause: $value",
                )
    }
}

internal data class RhythmDeliveryState(
    val revision: Long,
    val requestCode: Int,
    val registrationId: String?,
    val configuration: RhythmConfigurationState?,
    val presentation: RhythmNotificationPresentationState?,
    val occurrences: List<RhythmOccurrenceState>,
    val recoveryCause: RhythmDeliveryRecoveryCause?,
    val registeredBootCount: Int?,
) {
    val isActive: Boolean
        get() = registrationId != null

    val currentOccurrence: RhythmOccurrenceState?
        get() = occurrences.firstOrNull()

    val needsRecovery: Boolean
        get() = recoveryCause != null

    init {
        require(revision >= 0) { "revision must not be negative." }
        require(requestCode > 0) { "requestCode must be positive." }
        require(occurrences.size <= MAXIMUM_QUEUE_SIZE) {
            "occurrence queue exceeds the supported limit."
        }
        require(registeredBootCount == null || registeredBootCount >= 0) {
            "registeredBootCount must not be negative."
        }
        if (isActive) {
            require(revision > 0) { "an active state requires a positive revision." }
            requireBoundedText(
                registrationId!!,
                "registrationId",
                MAXIMUM_IDENTIFIER_LENGTH,
            )
            requireNotNull(configuration) { "an active state requires configuration." }
            requireNotNull(presentation) { "an active state requires presentation." }
            require(registrationId == "rhythm:$revision") {
                "registrationId must identify the active revision."
            }
            require(occurrences.isNotEmpty() || needsRecovery) {
                "an active state without occurrences must need recovery."
            }
            if (occurrences.isNotEmpty()) {
                validateChronologicalQueue(occurrences)
                occurrences.forEach { occurrence ->
                    val expectedPayload =
                        when (occurrence.kind) {
                            RhythmEventKindState.FOCUS_ENDS -> presentation.focusEnded
                            RhythmEventKindState.REST_ENDS -> presentation.restEnded
                        }
                    require(occurrence.payload == expectedPayload) {
                        "Occurrence payload must match the plan presentation."
                    }
                    require(occurrence.muted == presentation.muted) {
                        "Occurrence Mute must match the plan presentation."
                    }
                }
            }
        } else {
            require(configuration == null) { "an inactive state cannot have configuration." }
            require(presentation == null) { "an inactive state cannot have presentation." }
            require(occurrences.isEmpty()) { "an inactive state cannot have occurrences." }
            require(recoveryCause == null) { "an inactive state cannot need recovery." }
            require(registeredBootCount == null) {
                "an inactive state cannot have a registered boot count."
            }
        }
    }

    fun afterCurrentDelivery(): RhythmDeliveryState {
        check(isActive) { "Only an active state can consume an occurrence." }
        check(occurrences.isNotEmpty()) { "An active state must have a current occurrence." }
        val remaining = occurrences.drop(1)
        return copy(
            occurrences = remaining,
            recoveryCause =
                if (remaining.isEmpty()) {
                    RhythmDeliveryRecoveryCause.BACKGROUND_REFILL_FAILED
                } else {
                    null
                },
        )
    }

    fun skipOccurrencesAtOrBefore(observedAtEpochMillis: Long): RhythmDeliveryState {
        check(isActive) { "Only an active state can skip occurrences." }
        val remaining =
            occurrences.dropWhile { occurrence ->
                occurrence.occursAtEpochMillis <= observedAtEpochMillis
            }
        return copy(
            occurrences = remaining,
            recoveryCause =
                if (remaining.isEmpty()) {
                    RhythmDeliveryRecoveryCause.BACKGROUND_REFILL_FAILED
                } else {
                    null
                },
        )
    }

    fun markNeedsRecovery(
        cause: RhythmDeliveryRecoveryCause =
            RhythmDeliveryRecoveryCause.BACKGROUND_REFILL_FAILED,
    ): RhythmDeliveryState = copy(recoveryCause = cause)

    fun clearNeedsRecovery(): RhythmDeliveryState = copy(recoveryCause = null)

    fun registeredForBoot(bootCount: Int?): RhythmDeliveryState =
        copy(registeredBootCount = bootCount)

    fun interruptForRecovery(
        cause: RhythmDeliveryRecoveryCause,
    ): RhythmDeliveryState {
        check(isActive) { "Only active delivery can be interrupted for recovery." }
        check(revision < Long.MAX_VALUE) {
            "Android Rhythm delivery revision is exhausted."
        }
        val interruptedRevision = revision + 1
        return copy(
            revision = interruptedRevision,
            registrationId = "rhythm:$interruptedRevision",
            recoveryCause = cause,
        )
    }

    companion object {
        fun inactive(
            revision: Long,
            requestCode: Int = RHYTHM_ALARM_REQUEST_CODE,
        ): RhythmDeliveryState =
            RhythmDeliveryState(
                revision = revision,
                requestCode = requestCode,
                registrationId = null,
                configuration = null,
                presentation = null,
                occurrences = emptyList(),
                recoveryCause = null,
                registeredBootCount = null,
            )

        fun active(
            revision: Long,
            requestCode: Int,
            registrationId: String,
            configuration: RhythmConfigurationState,
            presentation: RhythmNotificationPresentationState,
            occurrences: List<RhythmOccurrenceState>,
            recoveryCause: RhythmDeliveryRecoveryCause? = null,
            registeredBootCount: Int? = null,
        ): RhythmDeliveryState =
            RhythmDeliveryState(
                revision = revision,
                requestCode = requestCode,
                registrationId = registrationId,
                configuration = configuration,
                presentation = presentation,
                occurrences = occurrences.toList(),
                recoveryCause = recoveryCause,
                registeredBootCount = registeredBootCount,
            )
    }
}

internal class MalformedRhythmDeliveryStateException(
    message: String,
    cause: Throwable? = null,
) : IOException(message, cause)

internal class MalformedRhythmDeliveryPlanException(
    message: String,
    cause: Throwable? = null,
) : IllegalArgumentException(message, cause)

internal class RhythmDeliveryStatePersistenceException(
    message: String,
    cause: Throwable? = null,
) : IOException(message, cause)

private data class RhythmRecoveryMetadata(
    val recoveryCause: RhythmDeliveryRecoveryCause?,
    val registeredBootCount: Int?,
    val isActive: Boolean,
)

internal object RhythmDeliveryStateCodec {
    fun encode(state: RhythmDeliveryState): ByteArray {
        try {
            val output = ByteArrayOutputStream()
            DataOutputStream(output).use { data ->
                data.writeInt(STATE_MAGIC)
                data.writeInt(RHYTHM_DELIVERY_STATE_SCHEMA_VERSION)
                data.writeLong(state.revision)
                data.writeInt(state.requestCode)
                data.writeBoolean(state.recoveryCause != null)
                if (state.recoveryCause != null) {
                    data.writeUTF(state.recoveryCause.wireName)
                }
                data.writeBoolean(state.registeredBootCount != null)
                if (state.registeredBootCount != null) {
                    data.writeInt(state.registeredBootCount)
                }
                data.writeBoolean(state.isActive)
                if (state.isActive) {
                    writeActiveState(data, state)
                }
            }
            return output.toByteArray()
        } catch (error: IOException) {
            throw RhythmDeliveryStatePersistenceException(
                "Could not encode Android Rhythm delivery state.",
                error,
            )
        }
    }

    fun decode(bytes: ByteArray): RhythmDeliveryState {
        try {
            DataInputStream(ByteArrayInputStream(bytes)).use { data ->
                val magic = data.readInt()
                if (magic != STATE_MAGIC) {
                    throw MalformedRhythmDeliveryStateException(
                        "Android Rhythm delivery state has an invalid header.",
                    )
                }
                val schemaVersion = data.readInt()
                val revision = data.readLong()
                val requestCode = data.readInt()
                val recoveryMetadata = readRecoveryMetadata(data, schemaVersion)
                if (
                    schemaVersion == RHYTHM_DELIVERY_STATE_SCHEMA_VERSION &&
                    !recoveryMetadata.isActive &&
                    (
                        recoveryMetadata.recoveryCause != null ||
                            recoveryMetadata.registeredBootCount != null
                    )
                ) {
                    throw MalformedRhythmDeliveryStateException(
                        "Inactive Android Rhythm state contains registration metadata.",
                    )
                }
                val state =
                    if (recoveryMetadata.isActive) {
                        readActiveState(
                            data = data,
                            revision = revision,
                            requestCode = requestCode,
                            recoveryCause = recoveryMetadata.recoveryCause,
                            registeredBootCount = recoveryMetadata.registeredBootCount,
                        )
                    } else {
                        RhythmDeliveryState.inactive(
                            revision = revision,
                            requestCode = requestCode,
                        )
                    }
                if (data.read() != -1) {
                    throw MalformedRhythmDeliveryStateException(
                        "Android Rhythm delivery state contains trailing bytes.",
                    )
                }
                return state
            }
        } catch (error: MalformedRhythmDeliveryStateException) {
            throw error
        } catch (error: EOFException) {
            throw MalformedRhythmDeliveryStateException(
                "Android Rhythm delivery state is truncated.",
                error,
            )
        } catch (error: IllegalArgumentException) {
            throw MalformedRhythmDeliveryStateException(
                "Android Rhythm delivery state violates its contract.",
                error,
            )
        } catch (error: IOException) {
            throw MalformedRhythmDeliveryStateException(
                "Could not decode Android Rhythm delivery state.",
                error,
            )
        }
    }

    private fun writeActiveState(
        data: DataOutputStream,
        state: RhythmDeliveryState,
    ) {
        data.writeUTF(state.registrationId!!)
        writeConfiguration(data, state.configuration!!)
        writePresentation(data, state.presentation!!)
        data.writeInt(state.occurrences.size)
        state.occurrences.forEach { occurrence ->
            data.writeUTF(occurrence.occurrenceId)
            data.writeUTF(occurrence.kind.wireName)
            data.writeLong(occurrence.occursAtEpochMillis)
            data.writeLong(occurrence.windowStartsAtEpochMillis)
            writePayload(data, occurrence.payload)
            data.writeBoolean(occurrence.muted)
        }
    }

    private fun readActiveState(
        data: DataInputStream,
        revision: Long,
        requestCode: Int,
        recoveryCause: RhythmDeliveryRecoveryCause?,
        registeredBootCount: Int?,
    ): RhythmDeliveryState {
        val registrationId = data.readUTF()
        val configuration = readConfiguration(data)
        val presentation = readPresentation(data)
        val queueSize = data.readInt()
        if (queueSize !in 0..MAXIMUM_QUEUE_SIZE) {
            throw MalformedRhythmDeliveryStateException(
                "Android Rhythm occurrence queue has an invalid size: $queueSize",
            )
        }
        val occurrences =
            List(queueSize) {
                RhythmOccurrenceState(
                    occurrenceId = data.readUTF(),
                    kind = RhythmEventKindState.parse(data.readUTF()),
                    occursAtEpochMillis = data.readLong(),
                    windowStartsAtEpochMillis = data.readLong(),
                    payload = readPayload(data),
                    muted = data.readBoolean(),
                )
            }
        return RhythmDeliveryState.active(
            revision = revision,
            requestCode = requestCode,
            registrationId = registrationId,
            configuration = configuration,
            presentation = presentation,
            occurrences = occurrences,
            recoveryCause = recoveryCause,
            registeredBootCount = registeredBootCount,
        )
    }

    private fun readRecoveryMetadata(
        data: DataInputStream,
        schemaVersion: Int,
    ): RhythmRecoveryMetadata =
        when (schemaVersion) {
            LEGACY_RHYTHM_DELIVERY_STATE_SCHEMA_VERSION -> {
                val needsRecovery = data.readBoolean()
                RhythmRecoveryMetadata(
                    recoveryCause =
                        if (needsRecovery) {
                            RhythmDeliveryRecoveryCause.BACKGROUND_REFILL_FAILED
                        } else {
                            null
                        },
                    registeredBootCount = null,
                    isActive = data.readBoolean(),
                )
            }
            RHYTHM_DELIVERY_STATE_SCHEMA_VERSION -> {
                val recoveryCause =
                    if (data.readBoolean()) {
                        RhythmDeliveryRecoveryCause.parse(data.readUTF())
                    } else {
                        null
                    }
                val registeredBootCount =
                    if (data.readBoolean()) {
                        data.readInt()
                    } else {
                        null
                    }
                RhythmRecoveryMetadata(
                    recoveryCause = recoveryCause,
                    registeredBootCount = registeredBootCount,
                    isActive = data.readBoolean(),
                )
            }
            else ->
                throw MalformedRhythmDeliveryStateException(
                    "Unsupported Android Rhythm state schema: $schemaVersion",
                )
        }

    private fun writeConfiguration(
        data: DataOutputStream,
        configuration: RhythmConfigurationState,
    ) {
        data.writeInt(configuration.focusMinutes)
        data.writeInt(configuration.restMinutes)
        data.writeUTF(configuration.dailyStart)
        data.writeUTF(configuration.dailyEnd)
    }

    private fun readConfiguration(data: DataInputStream): RhythmConfigurationState =
        RhythmConfigurationState(
            focusMinutes = data.readInt(),
            restMinutes = data.readInt(),
            dailyStart = data.readUTF(),
            dailyEnd = data.readUTF(),
        )

    private fun writePresentation(
        data: DataOutputStream,
        presentation: RhythmNotificationPresentationState,
    ) {
        writePayload(data, presentation.focusEnded)
        writePayload(data, presentation.restEnded)
        data.writeBoolean(presentation.muted)
    }

    private fun readPresentation(data: DataInputStream): RhythmNotificationPresentationState =
        RhythmNotificationPresentationState(
            focusEnded = readPayload(data),
            restEnded = readPayload(data),
            muted = data.readBoolean(),
        )

    private fun writePayload(
        data: DataOutputStream,
        payload: RhythmNotificationPayload,
    ) {
        data.writeUTF(payload.title)
        data.writeUTF(payload.body)
    }

    private fun readPayload(data: DataInputStream): RhythmNotificationPayload =
        RhythmNotificationPayload(
            title = data.readUTF(),
            body = data.readUTF(),
        )
}

internal interface AtomicRhythmStateFile {
    fun read(): ByteArray?

    fun replace(bytes: ByteArray)
}

internal fun interface AtomicRhythmFileReplacer {
    fun replace(source: File, destination: File)
}

internal object AndroidAtomicRhythmFileReplacer : AtomicRhythmFileReplacer {
    override fun replace(source: File, destination: File) {
        try {
            Os.rename(source.absolutePath, destination.absolutePath)
        } catch (error: ErrnoException) {
            throw RhythmDeliveryStatePersistenceException(
                "Could not atomically rename Android Rhythm delivery state.",
                error,
            )
        }
    }
}

internal class NoBackupAtomicRhythmStateFile(
    private val stateFile: File,
    private val fileReplacer: AtomicRhythmFileReplacer =
        AndroidAtomicRhythmFileReplacer,
) : AtomicRhythmStateFile {
    override fun read(): ByteArray? {
        if (!stateFile.exists()) {
            return null
        }
        try {
            return stateFile.readBytes()
        } catch (error: Exception) {
            throw RhythmDeliveryStatePersistenceException(
                "Could not read Android Rhythm delivery state.",
                error,
            )
        }
    }

    override fun replace(bytes: ByteArray) {
        val parent = stateFile.parentFile
            ?: throw RhythmDeliveryStatePersistenceException(
                "Android Rhythm state has no parent directory.",
            )
        if (!parent.exists() && !parent.mkdirs()) {
            throw RhythmDeliveryStatePersistenceException(
                "Could not create Android no-backup state directory.",
            )
        }
        val temporaryFile = File(parent, "${stateFile.name}.tmp")
        try {
            FileOutputStream(temporaryFile, false).use { output ->
                output.write(bytes)
                output.flush()
                output.fd.sync()
            }
            fileReplacer.replace(temporaryFile, stateFile)
        } catch (error: RhythmDeliveryStatePersistenceException) {
            throw error
        } catch (error: Exception) {
            throw RhythmDeliveryStatePersistenceException(
                "Could not atomically replace Android Rhythm delivery state.",
                error,
            )
        } finally {
            if (temporaryFile.exists()) {
                temporaryFile.delete()
            }
        }
    }
}

internal interface RhythmDeliveryStateRepository {
    fun load(): RhythmDeliveryState

    fun save(state: RhythmDeliveryState)
}

internal class RhythmDeliveryStateStore(
    private val stateFile: AtomicRhythmStateFile,
    private val initialRequestCode: Int = RHYTHM_ALARM_REQUEST_CODE,
) : RhythmDeliveryStateRepository {
    constructor(noBackupDirectory: File) : this(
        stateFile = NoBackupAtomicRhythmStateFile(
            File(noBackupDirectory, STATE_FILE_NAME),
        ),
    )

    override fun load(): RhythmDeliveryState {
        val bytes = stateFile.read()
            ?: return RhythmDeliveryState.inactive(
                revision = 0,
                requestCode = initialRequestCode,
            )
        return RhythmDeliveryStateCodec.decode(bytes)
    }

    override fun save(state: RhythmDeliveryState) {
        stateFile.replace(RhythmDeliveryStateCodec.encode(state))
    }
}

internal object RhythmDeliveryPlanChannelCodec {
    fun decodePlan(
        value: Any?,
        requestCode: Int = RHYTHM_ALARM_REQUEST_CODE,
    ): RhythmDeliveryState {
        try {
            val map = requireMap(value, "plan")
            val schemaVersion = requireInt(map["schemaVersion"], "schemaVersion")
            if (schemaVersion != RHYTHM_DELIVERY_SCHEMA_VERSION) {
                throw MalformedRhythmDeliveryStateException(
                    "Unsupported Android Rhythm delivery schema: $schemaVersion",
                )
            }
            return RhythmDeliveryState.active(
                revision = requirePositiveLong(map["revision"], "revision"),
                requestCode = requestCode,
                registrationId = requireText(map["registrationId"], "registrationId"),
                configuration = decodeConfiguration(
                    requireMap(map["configuration"], "configuration"),
                ),
                presentation = decodePresentation(
                    requireMap(map["presentation"], "presentation"),
                ),
                occurrences = requireList(map["occurrences"], "occurrences")
                    .map { occurrence ->
                        decodeOccurrence(requireMap(occurrence, "occurrences[]"))
                    },
            )
        } catch (error: MalformedRhythmDeliveryPlanException) {
            throw error
        } catch (error: Exception) {
            throw MalformedRhythmDeliveryPlanException(
                "Android Rhythm plan violates its contract.",
                error,
            )
        }
    }

    fun encodeStatus(state: RhythmDeliveryState): Map<String, Any?> =
        mapOf(
            "revision" to state.revision,
            "isActive" to state.isActive,
            "needsRecovery" to state.needsRecovery,
            "recoveryReason" to state.recoveryCause?.wireName,
            "registeredBootCount" to state.registeredBootCount,
            "activePlan" to
                if (state.isActive && state.occurrences.isNotEmpty()) {
                    encodePlan(state)
                } else {
                    null
                },
        )

    fun encodeStartupAudit(result: RhythmStartupAuditResult): Map<String, Any?> =
        mapOf(
            "lifecycleReason" to result.lifecycleReason.wireName,
            "disposition" to result.decision.disposition.wireName,
            "recoveryReason" to result.decision.cause?.wireName,
            "observedAtEpochMillis" to result.observedAtEpochMillis,
            "revision" to result.state.revision,
            "configuration" to
                result.state.configuration?.let(::encodeConfiguration),
        )

    fun encodePlan(state: RhythmDeliveryState): Map<String, Any?> {
        check(state.isActive) { "Only active state can be encoded as a plan." }
        return mapOf(
            "schemaVersion" to RHYTHM_DELIVERY_SCHEMA_VERSION,
            "revision" to state.revision,
            "registrationId" to state.registrationId,
            "configuration" to encodeConfiguration(state.configuration!!),
            "presentation" to encodePresentation(state.presentation!!),
            "occurrences" to state.occurrences.map(::encodeOccurrence),
        )
    }

    fun encodeBackgroundRequest(
        state: RhythmDeliveryState,
        observedAtEpochMillis: Long,
    ): Map<String, Any?> {
        check(state.isActive) { "Only active state can request background refill." }
        return mapOf(
            "expectedRevision" to state.revision,
            "observedAtEpochMillis" to observedAtEpochMillis,
            "configuration" to encodeConfiguration(state.configuration!!),
            "presentation" to encodePresentation(state.presentation!!),
        )
    }

    private fun decodeConfiguration(map: Map<*, *>): RhythmConfigurationState =
        RhythmConfigurationState(
            focusMinutes = requireInt(map["focusMinutes"], "focusMinutes"),
            restMinutes = requireInt(map["restMinutes"], "restMinutes"),
            dailyStart = requireText(map["dailyStart"], "dailyStart"),
            dailyEnd = requireText(map["dailyEnd"], "dailyEnd"),
        )

    private fun decodePresentation(map: Map<*, *>): RhythmNotificationPresentationState =
        RhythmNotificationPresentationState(
            focusEnded = decodePayload(
                requireMap(map["focusEnded"], "presentation.focusEnded"),
            ),
            restEnded = decodePayload(
                requireMap(map["restEnded"], "presentation.restEnded"),
            ),
            muted = requireBoolean(map["muted"], "presentation.muted"),
        )

    private fun decodeOccurrence(map: Map<*, *>): RhythmOccurrenceState =
        RhythmOccurrenceState(
            occurrenceId = requireText(map["occurrenceId"], "occurrenceId"),
            kind = RhythmEventKindState.parse(requireText(map["kind"], "kind")),
            occursAtEpochMillis = requireLong(
                map["occursAtEpochMillis"],
                "occursAtEpochMillis",
            ),
            windowStartsAtEpochMillis = requireLong(
                map["windowStartsAtEpochMillis"],
                "windowStartsAtEpochMillis",
            ),
            payload = RhythmNotificationPayload(
                title = requireText(map["title"], "title"),
                body = requireText(map["body"], "body"),
            ),
            muted = requireBoolean(map["muted"], "muted"),
        )

    private fun decodePayload(map: Map<*, *>): RhythmNotificationPayload =
        RhythmNotificationPayload(
            title = requireText(map["title"], "title"),
            body = requireText(map["body"], "body"),
        )

    private fun encodeConfiguration(
        configuration: RhythmConfigurationState,
    ): Map<String, Any?> =
        mapOf(
            "focusMinutes" to configuration.focusMinutes,
            "restMinutes" to configuration.restMinutes,
            "dailyStart" to configuration.dailyStart,
            "dailyEnd" to configuration.dailyEnd,
        )

    private fun encodePresentation(
        presentation: RhythmNotificationPresentationState,
    ): Map<String, Any?> =
        mapOf(
            "focusEnded" to encodePayload(presentation.focusEnded),
            "restEnded" to encodePayload(presentation.restEnded),
            "muted" to presentation.muted,
        )

    private fun encodeOccurrence(occurrence: RhythmOccurrenceState): Map<String, Any?> =
        mapOf(
            "occurrenceId" to occurrence.occurrenceId,
            "kind" to occurrence.kind.wireName,
            "occursAtEpochMillis" to occurrence.occursAtEpochMillis,
            "windowStartsAtEpochMillis" to occurrence.windowStartsAtEpochMillis,
            "title" to occurrence.payload.title,
            "body" to occurrence.payload.body,
            "muted" to occurrence.muted,
        )

    private fun encodePayload(payload: RhythmNotificationPayload): Map<String, Any?> =
        mapOf(
            "title" to payload.title,
            "body" to payload.body,
        )
}

internal fun requireMap(value: Any?, field: String): Map<*, *> =
    value as? Map<*, *>
        ?: throw MalformedRhythmDeliveryStateException("$field must be a map.")

internal fun requireList(value: Any?, field: String): List<*> =
    value as? List<*>
        ?: throw MalformedRhythmDeliveryStateException("$field must be a list.")

internal fun requireText(value: Any?, field: String): String {
    val text = value as? String
        ?: throw MalformedRhythmDeliveryStateException("$field must be a string.")
    if (text.isBlank()) {
        throw MalformedRhythmDeliveryStateException("$field must not be blank.")
    }
    return text
}

internal fun requireBoolean(value: Any?, field: String): Boolean =
    value as? Boolean
        ?: throw MalformedRhythmDeliveryStateException("$field must be a boolean.")

internal fun requireInt(value: Any?, field: String): Int =
    when (value) {
        is Int -> value
        is Long ->
            if (value in Int.MIN_VALUE..Int.MAX_VALUE) {
                value.toInt()
            } else {
                throw MalformedRhythmDeliveryStateException("$field is out of range.")
            }
        else -> throw MalformedRhythmDeliveryStateException("$field must be an integer.")
    }

internal fun requireLong(value: Any?, field: String): Long =
    when (value) {
        is Int -> value.toLong()
        is Long -> value
        else -> throw MalformedRhythmDeliveryStateException("$field must be an integer.")
    }

internal fun requirePositiveLong(value: Any?, field: String): Long {
    val parsed = requireLong(value, field)
    if (parsed <= 0) {
        throw MalformedRhythmDeliveryStateException("$field must be positive.")
    }
    return parsed
}

private fun validateChronologicalQueue(occurrences: List<RhythmOccurrenceState>) {
    val identifiers = mutableSetOf<String>()
    var previousEpochMillis: Long? = null
    occurrences.forEach { occurrence ->
        require(
            occurrence.occurrenceId ==
                "${occurrence.occursAtEpochMillis}:${occurrence.kind.wireName}",
        ) {
            "Occurrence ID must identify its timestamp and kind."
        }
        require(identifiers.add(occurrence.occurrenceId)) {
            "Occurrence IDs must be unique."
        }
        val previous = previousEpochMillis
        require(previous == null || occurrence.occursAtEpochMillis > previous) {
            "Occurrences must be strictly chronological."
        }
        previousEpochMillis = occurrence.occursAtEpochMillis
    }
}

private fun requireBoundedText(
    value: String,
    field: String,
    maximumLength: Int,
) {
    require(value.isNotBlank()) { "$field must not be blank." }
    require(value.length <= maximumLength) { "$field is too long." }
}

private fun requireClockTime(value: String, field: String) {
    require(Regex("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$").matches(value)) {
        "$field must be strict HH:mm."
    }
}
