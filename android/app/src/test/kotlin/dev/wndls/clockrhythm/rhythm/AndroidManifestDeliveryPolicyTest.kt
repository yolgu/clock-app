package dev.wndls.clockrhythm.rhythm

import java.io.File

class AndroidManifestDeliveryPolicyTest {
    @Test
    fun `declares only user-granted delivery permissions and no service`() {
        val manifest = File("src/main/AndroidManifest.xml").readText()

        assertContains(manifest, "android.permission.POST_NOTIFICATIONS")
        assertContains(manifest, "android.permission.SCHEDULE_EXACT_ALARM")
        forbiddenTokens.forEach { token ->
            assertFalse(
                manifest.contains(token),
                "Android delivery manifest must not contain $token",
            )
        }
    }

    @Test
    fun `uses one-shot PendingIntent identity for actual registration audit`() {
        val scheduler =
            File(
                "src/main/kotlin/dev/wndls/clockrhythm/rhythm/" +
                    "RhythmExactAlarmScheduler.kt",
            ).readText()

        assertEquals(
            3,
            Regex("PendingIntent\\.FLAG_ONE_SHOT").findAll(scheduler).count(),
        )
    }

    private companion object {
        val forbiddenTokens =
            listOf(
                "android.permission.USE_EXACT_ALARM",
                "android.permission.FOREGROUND_SERVICE",
                "android.permission.USE_FULL_SCREEN_INTENT",
                "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS",
                "android.permission.READ_EXTERNAL_STORAGE",
                "android.permission.WRITE_EXTERNAL_STORAGE",
                "android.permission.MANAGE_EXTERNAL_STORAGE",
                "<service",
            )
    }
}
