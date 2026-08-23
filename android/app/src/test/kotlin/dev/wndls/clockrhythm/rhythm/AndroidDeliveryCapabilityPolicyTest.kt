package dev.wndls.clockrhythm.rhythm

class AndroidDeliveryCapabilityPolicyTest {
    @Test
    fun `applies the API 24 31 33 and 36 capability table`() {
        val scenarios =
            listOf(
                CapabilityScenario(
                    sdkInt = 24,
                    notificationGranted = true,
                    exactAlarmGranted = false,
                    expected = null,
                ),
                CapabilityScenario(
                    sdkInt = 24,
                    notificationGranted = false,
                    exactAlarmGranted = true,
                    expected = AndroidDeliveryCapabilityFailure.NOTIFICATION_PERMISSION,
                ),
                CapabilityScenario(
                    sdkInt = 31,
                    notificationGranted = true,
                    exactAlarmGranted = false,
                    expected = AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION,
                ),
                CapabilityScenario(
                    sdkInt = 33,
                    notificationGranted = false,
                    exactAlarmGranted = true,
                    expected = AndroidDeliveryCapabilityFailure.NOTIFICATION_PERMISSION,
                ),
                CapabilityScenario(
                    sdkInt = 33,
                    notificationGranted = true,
                    exactAlarmGranted = false,
                    expected = AndroidDeliveryCapabilityFailure.EXACT_ALARM_PERMISSION,
                ),
                CapabilityScenario(
                    sdkInt = 36,
                    notificationGranted = false,
                    exactAlarmGranted = false,
                    expected =
                        AndroidDeliveryCapabilityFailure
                            .NOTIFICATION_AND_EXACT_ALARM_PERMISSION,
                ),
            )

        scenarios.forEach { scenario ->
            val status =
                AndroidDeliveryCapabilityPolicy.evaluate(
                    sdkInt = scenario.sdkInt,
                    notificationGranted = scenario.notificationGranted,
                    exactAlarmGranted = scenario.exactAlarmGranted,
                )
            assertEquals(scenario.expected, status.failure)
        }
    }

    @Test
    fun `grants API 36 only when both requirements are present`() {
        val status =
            AndroidDeliveryCapabilityPolicy.evaluate(
                sdkInt = 36,
                notificationGranted = true,
                exactAlarmGranted = true,
            )

        assertNull(status.failure)
    }
}

private data class CapabilityScenario(
    val sdkInt: Int,
    val notificationGranted: Boolean,
    val exactAlarmGranted: Boolean,
    val expected: AndroidDeliveryCapabilityFailure?,
)
