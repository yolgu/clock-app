package dev.wndls.clockrhythm.rhythm

import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element

class AndroidBackupPolicyTest {
    @Test
    fun `legacy backup is a flavor-specific conditional database-file allowlist`() {
        flavorDatabaseFiles.forEach { (flavor, databaseFiles) ->
            val root = xmlRoot("src/$flavor/res/xml/backup_rules.xml")
            assertEquals("full-backup-content", root.tagName)

            val includes = childElements(root, "include")
            assertEquals(4, includes.size)
            assertEquals(databaseFiles, includes.map(::path).toSet())
            assertEquals(setOf("file"), includes.map(::domain).toSet())
            assertEquals(
                setOf("clientSideEncryption", "deviceToDeviceTransfer"),
                includes.map { element -> element.getAttribute("requireFlags") }.toSet(),
            )
            assertNoBroadOrDeviceStateRule(root)
        }
    }

    @Test
    fun `API 31 backup separates each flavor encrypted cloud from device transfer`() {
        flavorDatabaseFiles.forEach { (flavor, databaseFiles) ->
            val root = xmlRoot("src/$flavor/res/xml/data_extraction_rules.xml")
            assertEquals("data-extraction-rules", root.tagName)
            val cloud = childElements(root, "cloud-backup").single()
            val deviceTransfer = childElements(root, "device-transfer").single()

            assertEquals("true", cloud.getAttribute("disableIfNoEncryptionCapabilities"))
            assertDatabaseFileAllowlist(cloud, databaseFiles)
            assertDatabaseFileAllowlist(deviceTransfer, databaseFiles)
            assertNoBroadOrDeviceStateRule(root)
        }
    }

    @Test
    fun `manifest connects both backup schemas and lifecycle broadcasts`() {
        val manifest = File("src/main/AndroidManifest.xml").readText()

        listOf(
            "android:allowBackup=\"true\"",
            "android:fullBackupContent=\"@xml/backup_rules\"",
            "android:dataExtractionRules=\"@xml/data_extraction_rules\"",
            "android.permission.RECEIVE_BOOT_COMPLETED",
            ".rhythm.RhythmLifecycleReceiver",
            "android.intent.action.BOOT_COMPLETED",
            "android.intent.action.MY_PACKAGE_REPLACED",
            "android.intent.action.TIME_SET",
            "android.intent.action.TIMEZONE_CHANGED",
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
        ).forEach { token -> assertContains(manifest, token) }
    }

    @Test
    fun `manifest introduces no remote or account surface`() {
        val manifest = File("src/main/AndroidManifest.xml").readText()
        listOf(
            "android.permission.INTERNET",
            "android.permission.GET_ACCOUNTS",
            "android.permission.MANAGE_ACCOUNTS",
            "android.permission.AUTHENTICATE_ACCOUNTS",
            "<account-authenticator",
            "firebase",
            "analytics",
            "crashlytics",
        ).forEach { token ->
            assertFalse(
                manifest.contains(token, ignoreCase = true),
                "Android manifest must not contain $token",
            )
        }
    }

    private fun assertDatabaseFileAllowlist(
        section: Element,
        expectedDatabaseFiles: Set<String>,
    ) {
        val includes = childElements(section, "include")
        assertEquals(2, includes.size)
        assertEquals(expectedDatabaseFiles, includes.map(::path).toSet())
        assertEquals(setOf("file"), includes.map(::domain).toSet())
    }

    private fun assertNoBroadOrDeviceStateRule(root: Element) {
        val allElements = root.getElementsByTagName("*")
        for (index in 0 until allElements.length) {
            val element = allElements.item(index) as Element
            if (element.tagName != "include" && element.tagName != "exclude") {
                continue
            }
            assertFalse(element.getAttribute("path") == ".", "Broad backup paths are forbidden.")
            assertFalse(
                element.getAttribute("domain") in forbiddenDomains,
                "Device state backup domains are forbidden.",
            )
        }
    }

    private fun xmlRoot(path: String): Element {
        val factory = DocumentBuilderFactory.newInstance()
        factory.isNamespaceAware = true
        return factory.newDocumentBuilder().parse(File(path)).documentElement
    }

    private fun childElements(
        parent: Element,
        tagName: String,
    ): List<Element> {
        val matches = mutableListOf<Element>()
        val children = parent.childNodes
        for (index in 0 until children.length) {
            val child = children.item(index)
            if (child is Element && child.tagName == tagName) {
                matches.add(child)
            }
        }
        return matches
    }

    private fun path(element: Element): String = element.getAttribute("path")

    private fun domain(element: Element): String = element.getAttribute("domain")

    private companion object {
        val flavorDatabaseFiles =
            mapOf(
                "beta" to
                    setOf(
                        "clock_rhythm_beta.sqlite",
                        "clock_rhythm_beta.sqlite-journal",
                    ),
                "production" to
                    setOf(
                        "clock_rhythm.sqlite",
                        "clock_rhythm.sqlite-journal",
                    ),
            )
        val forbiddenDomains =
            setOf(
                "root",
                "database",
                "sharedpref",
                "external",
                "device_root",
                "device_file",
                "device_database",
                "device_sharedpref",
            )
    }
}
