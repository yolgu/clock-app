package dev.wndls.clockrhythm.rhythm

import java.io.ByteArrayOutputStream
import java.io.DataOutputStream

class RhythmDeliveryStateCodecTest {
    @Test
    fun `round trips revisioned active state`() {
        val original = deliveryState(revision = 7)

        val restored = RhythmDeliveryStateCodec.decode(
            RhythmDeliveryStateCodec.encode(original),
        )

        assertEquals(original, restored)
    }

    @Test
    fun `rejects malformed state instead of treating it as idle`() {
        assertFailsWith<MalformedRhythmDeliveryStateException> {
            RhythmDeliveryStateCodec.decode(byteArrayOf(1, 2, 3))
        }
    }

    @Test
    fun `round trips the typed Dart channel plan contract`() {
        val original = deliveryState(revision = 19)

        val restored =
            RhythmDeliveryPlanChannelCodec.decodePlan(
                RhythmDeliveryPlanChannelCodec.encodePlan(original),
            )

        assertEquals(original, restored)
    }

    @Test
    fun `round trips recovery cause and registered boot count`() {
        val original =
            deliveryState(revision = 23).copy(
                recoveryCause =
                    RhythmDeliveryRecoveryCause.REGISTRATION_MISSING,
                registeredBootCount = 17,
            )

        val restored = RhythmDeliveryStateCodec.decode(
            RhythmDeliveryStateCodec.encode(original),
        )

        assertEquals(original, restored)
    }

    @Test
    fun `upgrades a version one recovery marker without inventing boot evidence`() {
        val restored = RhythmDeliveryStateCodec.decode(versionOneState())

        assertEquals(5L, restored.revision)
        assertEquals(
            RhythmDeliveryRecoveryCause.BACKGROUND_REFILL_FAILED,
            restored.recoveryCause,
        )
        assertNull(restored.registeredBootCount)
    }

    private fun versionOneState(): ByteArray {
        val output = ByteArrayOutputStream()
        DataOutputStream(output).use { data ->
            data.writeInt(0x43524859)
            data.writeInt(1)
            data.writeLong(5)
            data.writeInt(41_001)
            data.writeBoolean(true)
            data.writeBoolean(true)
            data.writeUTF("rhythm:5")
            data.writeInt(50)
            data.writeInt(10)
            data.writeUTF("05:00")
            data.writeUTF("18:00")
            data.writeUTF("Focus ended")
            data.writeUTF("Take a rest.")
            data.writeUTF("Rest ended")
            data.writeUTF("Return to focus.")
            data.writeBoolean(false)
            data.writeInt(1)
            data.writeUTF("1000:focusEnds")
            data.writeUTF("focusEnds")
            data.writeLong(1_000)
            data.writeLong(0)
            data.writeUTF("Focus ended")
            data.writeUTF("Take a rest.")
            data.writeBoolean(false)
        }
        return output.toByteArray()
    }
}

internal fun deliveryState(revision: Long): RhythmDeliveryState =
    RhythmDeliveryState.active(
        revision = revision,
        requestCode = 41_001,
        registrationId = "rhythm:$revision",
        configuration = RhythmConfigurationState(
            focusMinutes = 50,
            restMinutes = 10,
            dailyStart = "05:00",
            dailyEnd = "18:00",
        ),
        presentation = RhythmNotificationPresentationState(
            focusEnded = RhythmNotificationPayload("Focus ended", "Take a rest."),
            restEnded = RhythmNotificationPayload("Rest ended", "Return to focus."),
            muted = false,
        ),
        occurrences = listOf(
            RhythmOccurrenceState(
                occurrenceId = "1000:focusEnds",
                kind = RhythmEventKindState.FOCUS_ENDS,
                occursAtEpochMillis = 1_000,
                windowStartsAtEpochMillis = 0,
                payload = RhythmNotificationPayload("Focus ended", "Take a rest."),
                muted = false,
            ),
            RhythmOccurrenceState(
                occurrenceId = "2000:restEnds",
                kind = RhythmEventKindState.REST_ENDS,
                occursAtEpochMillis = 2_000,
                windowStartsAtEpochMillis = 0,
                payload = RhythmNotificationPayload("Rest ended", "Return to focus."),
                muted = false,
            ),
            RhythmOccurrenceState(
                occurrenceId = "3000:focusEnds",
                kind = RhythmEventKindState.FOCUS_ENDS,
                occursAtEpochMillis = 3_000,
                windowStartsAtEpochMillis = 0,
                payload = RhythmNotificationPayload("Focus ended", "Take a rest."),
                muted = false,
            ),
        ),
    )
