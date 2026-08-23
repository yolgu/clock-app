package dev.wndls.clockrhythm.rhythm

import dev.wndls.clockrhythm.BuildConfig
import java.io.File

class AndroidFlavorPackagingPolicyTest {
    @Test
    fun `notification channel belongs to the installed application identity`() {
        assertEquals(
            "${BuildConfig.APPLICATION_ID}.rhythm-events",
            BuildConfig.RHYTHM_NOTIFICATION_CHANNEL_ID,
        )
    }

    @Test
    fun `Gradle declares exact side-by-side identities and external signing boundary`() {
        val buildScript = File("build.gradle.kts").readText()

        listOf(
            "applicationId = \"dev.wndls.clockrhythm.beta\"",
            "applicationId = \"dev.wndls.clockrhythm\"",
            "CLOCK_RHYTHM_ANDROID_KEYSTORE",
            "CLOCK_RHYTHM_ANDROID_KEY_ALIAS",
            "CLOCK_RHYTHM_ANDROID_STORE_PASSWORD",
            "CLOCK_RHYTHM_ANDROID_KEY_PASSWORD",
        ).forEach { contract -> assertContains(buildScript, contract) }
        assertFalse(
            Regex("(?i)(storePassword|keyPassword)\\s*=\\s*\"[^\"]+\"")
                .containsMatchIn(buildScript),
            "Production signing passwords must not be literals.",
        )
    }
}
