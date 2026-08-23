package dev.wndls.clockrhythm.rhythm

import java.io.File

class AndroidDiagnosticPrivacyPolicyTest {
    @Test
    fun `native release logs contain stable codes without exception or payload data`() {
        val sourceDirectory =
            File("src/main/kotlin/dev/wndls/clockrhythm/rhythm")
        val logLines =
            sourceDirectory
                .walkTopDown()
                .filter { file -> file.isFile && file.extension == "kt" }
                .flatMap { file ->
                    file.readLines().asSequence().filter { line -> "Log." in line }
                }.toList()

        assertEquals(3, logLines.size)
        logLines.forEach { line ->
            assertTrue(
                STABLE_LOG_PATTERN.matches(line.trim()),
                "Android Rhythm logs must emit only a stable diagnostic code: $line",
            )
        }
    }

    private companion object {
        val STABLE_LOG_PATTERN = Regex("Log\\.e\\(TAG, \\\"[A-Z0-9_]+\\\"\\)")
    }
}
