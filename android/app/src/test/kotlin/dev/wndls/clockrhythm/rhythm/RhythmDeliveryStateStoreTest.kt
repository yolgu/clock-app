package dev.wndls.clockrhythm.rhythm

import java.io.IOException
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

class RhythmDeliveryStateStoreTest {
    @Test
    fun `persists and restores state through an atomic file`() {
        val directory = Files.createTempDirectory("clock-rhythm-state-test").toFile()
        try {
            val stateFile =
                NoBackupAtomicRhythmStateFile(
                    stateFile = File(directory, "state.bin"),
                    fileReplacer =
                        AtomicRhythmFileReplacer { source, destination ->
                            Files.move(
                                source.toPath(),
                                destination.toPath(),
                                StandardCopyOption.ATOMIC_MOVE,
                                StandardCopyOption.REPLACE_EXISTING,
                            )
                        },
                )
            val store = RhythmDeliveryStateStore(stateFile)
            val state = deliveryState(revision = 17)

            store.save(state)

            assertEquals(state, store.load())
        } finally {
            directory.deleteRecursively()
        }
    }

    @Test
    fun `failed replacement preserves the previously committed state`() {
        val atomicFile = FaultInjectingAtomicStateFile()
        val store = RhythmDeliveryStateStore(atomicFile)
        val original = deliveryState(revision = 2)
        store.save(original)
        atomicFile.failReplacement = true

        assertFailsWith<RhythmDeliveryStatePersistenceException> {
            store.save(deliveryState(revision = 3))
        }

        assertEquals(original, store.load())
    }
}

private class FaultInjectingAtomicStateFile : AtomicRhythmStateFile {
    var committed: ByteArray? = null
    var failReplacement: Boolean = false

    override fun read(): ByteArray? = committed

    override fun replace(bytes: ByteArray) {
        if (failReplacement) {
            throw RhythmDeliveryStatePersistenceException(
                "Injected replacement failure.",
                IOException("fault"),
            )
        }
        committed = bytes.copyOf()
    }
}
