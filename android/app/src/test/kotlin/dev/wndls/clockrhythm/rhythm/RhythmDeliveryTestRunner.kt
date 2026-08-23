package dev.wndls.clockrhythm.rhythm

import java.lang.reflect.InvocationTargetException

@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.RUNTIME)
internal annotation class Test

internal fun assertTrue(
    actual: Boolean,
    message: String = "Expected condition to be true.",
) {
    if (!actual) {
        throw AssertionError(message)
    }
}

internal fun assertFalse(
    actual: Boolean,
    message: String = "Expected condition to be false.",
) {
    if (actual) {
        throw AssertionError(message)
    }
}

internal fun assertNull(actual: Any?) {
    if (actual != null) {
        throw AssertionError("Expected null but was <$actual>.")
    }
}

internal fun assertEquals(
    expected: Any?,
    actual: Any?,
) {
    if (expected != actual) {
        throw AssertionError("Expected <$expected> but was <$actual>.")
    }
}

internal fun assertContains(
    actual: CharSequence,
    expected: CharSequence,
) {
    if (!actual.contains(expected)) {
        throw AssertionError("Expected text to contain <$expected>.")
    }
}

internal inline fun <reified T : Throwable> assertFailsWith(
    block: () -> Unit,
): T {
    try {
        block()
    } catch (error: Throwable) {
        if (error is T) {
            return error
        }
        val assertion =
            AssertionError(
                "Expected ${T::class.java.name} but caught ${error.javaClass.name}.",
            )
        assertion.initCause(error)
        throw assertion
    }
    throw AssertionError("Expected ${T::class.java.name} to be thrown.")
}

internal object RhythmDeliveryTestRunner {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "Android Rhythm unit tests do not accept arguments." }
        val testClasses =
            listOf(
                AndroidDeliveryCapabilityPolicyTest::class.java,
                AndroidBackupPolicyTest::class.java,
                AndroidFlavorPackagingPolicyTest::class.java,
                AndroidManifestDeliveryPolicyTest::class.java,
                AndroidDiagnosticPrivacyPolicyTest::class.java,
                RhythmDeliveryCoordinatorTest::class.java,
                RhythmDeliveryStateCodecTest::class.java,
                RhythmDeliveryStateStoreTest::class.java,
                RhythmLifecycleDecisionTableTest::class.java,
                RhythmStartupAuditTest::class.java,
            )
        var passed = 0
        testClasses.forEach { testClass ->
            val instance = testClass.getDeclaredConstructor().newInstance()
            testClass.declaredMethods
                .filter { method -> method.isAnnotationPresent(Test::class.java) }
                .sortedBy { method -> method.name }
                .forEach { method ->
                    try {
                        method.invoke(instance)
                        passed += 1
                    } catch (error: InvocationTargetException) {
                        val cause = error.cause ?: error
                        val assertion =
                            AssertionError(
                                "${testClass.simpleName}.${method.name} failed: " +
                                    cause.message,
                            )
                        assertion.initCause(cause)
                        throw assertion
                    }
                }
        }
        check(passed == EXPECTED_TEST_COUNT) {
            "Expected $EXPECTED_TEST_COUNT Android Rhythm tests but ran $passed."
        }
        println("Android Rhythm unit tests: $passed passed, 0 failed.")
    }

    private const val EXPECTED_TEST_COUNT: Int = 43
}
