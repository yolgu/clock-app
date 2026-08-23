package dev.wndls.clockrhythm.rhythm

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

private const val LIFECYCLE_ENTRYPOINT_LIBRARY: String =
    "package:clock_rhythm/contexts/rhythm/infrastructure/android/" +
        "android_delivery_recovery_adapter.dart"
private const val LIFECYCLE_ENTRYPOINT_FUNCTION: String =
    "androidRhythmLifecycleMain"
private const val LIFECYCLE_TIMEOUT_MILLIS: Long = 8_000

internal class RhythmLifecycleFlutterCoordinator(
    context: Context,
    private val deliveryCoordinator: RhythmDeliveryCoordinator,
    private val handler: Handler = Handler(Looper.getMainLooper()),
) {
    private val applicationContext = context.applicationContext
    private var activeAudit: RhythmStartupAuditResult? = null
    private var activeOnFinished: (() -> Unit)? = null
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private val finished = AtomicBoolean(false)
    private val timeout = Runnable { finish() }

    fun requestReconciliation(
        audit: RhythmStartupAuditResult,
        onFinished: () -> Unit,
    ): Unit {
        require(
            audit.decision.disposition ==
                RhythmRecoveryDisposition.RECONCILE_AUTOMATICALLY,
        ) { "Lifecycle reconciliation requires an automatic audit decision." }
        if (!RhythmHeadlessExecutionGate.busy.compareAndSet(false, true)) {
            onFinished()
            return
        }
        activeAudit = audit
        activeOnFinished = onFinished
        try {
            startEngine()
            handler.postDelayed(timeout, LIFECYCLE_TIMEOUT_MILLIS)
        } catch (_: Exception) {
            finish()
        }
    }

    private fun startEngine(): Unit {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "Lifecycle Flutter engine must start on the Android main thread."
        }
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val startedEngine = FlutterEngine(applicationContext, null, false)
        val startedChannel =
            MethodChannel(
                startedEngine.dartExecutor.binaryMessenger,
                RhythmAlarmChannelContract.CHANNEL_NAME,
            )
        startedChannel.setMethodCallHandler(::handleMethodCall)
        engine = startedEngine
        channel = startedChannel
        startedEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                LIFECYCLE_ENTRYPOINT_LIBRARY,
                LIFECYCLE_ENTRYPOINT_FUNCTION,
            ),
        )
    }

    private fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ): Unit {
        try {
            when (call.method) {
                RhythmAlarmChannelContract.LIFECYCLE_READY ->
                    result.success(lifecycleRequestMap())
                RhythmAlarmChannelContract.COMPLETE_LIFECYCLE_RECONCILE ->
                    completeReconciliation(call.arguments, result)
                RhythmAlarmChannelContract.LIFECYCLE_RECONCILE_FAILED -> {
                    result.success(null)
                    handler.post(::finish)
                }
                else -> result.notImplemented()
            }
        } catch (error: MalformedRhythmDeliveryStateException) {
            result.error("invalidPayload", error.message, null)
            finish()
        } catch (error: MalformedRhythmDeliveryPlanException) {
            result.error("invalidPayload", error.message, null)
            finish()
        } catch (_: Exception) {
            result.error(
                "lifecycleReconcileFailed",
                "Android Rhythm lifecycle reconciliation failed.",
                null,
            )
            finish()
        }
    }

    private fun lifecycleRequestMap(): Map<String, Any?> {
        val audit = requireActiveAudit()
        return RhythmDeliveryPlanChannelCodec.encodeBackgroundRequest(
            state = audit.state,
            observedAtEpochMillis = audit.observedAtEpochMillis,
        ) + mapOf("lifecycleReason" to audit.lifecycleReason.wireName)
    }

    private fun completeReconciliation(
        arguments: Any?,
        result: MethodChannel.Result,
    ): Unit {
        val map = requireMap(arguments, "completeLifecycleReconcile")
        val expectedRevision =
            requirePositiveLong(map["expectedRevision"], "expectedRevision")
        val audit = requireActiveAudit()
        if (expectedRevision != audit.state.revision) {
            throw MalformedRhythmDeliveryStateException(
                "Lifecycle reconcile revision does not match its request.",
            )
        }
        val replacement =
            RhythmDeliveryPlanChannelCodec.decodePlan(
                map["plan"],
                audit.state.requestCode,
            )
        val adopted =
            deliveryCoordinator.complete(
                expectedRevision = expectedRevision,
                observedAtEpochMillis = audit.observedAtEpochMillis,
                replacement = replacement,
            )
        result.success(mapOf("adopted" to adopted))
        handler.post(::finish)
    }

    private fun requireActiveAudit(): RhythmStartupAuditResult =
        checkNotNull(activeAudit) {
            "No Android Rhythm lifecycle reconciliation is active."
        }

    private fun finish(): Unit {
        if (!finished.compareAndSet(false, true)) {
            return
        }
        handler.removeCallbacks(timeout)
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
        activeAudit = null
        val onFinished = activeOnFinished
        activeOnFinished = null
        RhythmHeadlessExecutionGate.busy.set(false)
        onFinished?.invoke()
    }
}
