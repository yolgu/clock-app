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

private const val BACKGROUND_ENTRYPOINT_LIBRARY: String =
    "package:clock_rhythm/contexts/rhythm/infrastructure/android/" +
        "android_background_entrypoint.dart"
private const val BACKGROUND_ENTRYPOINT_FUNCTION: String =
    "androidRhythmBackgroundMain"
private const val BACKGROUND_TIMEOUT_MILLIS: Long = 8_000

internal object RhythmHeadlessExecutionGate {
    val busy: AtomicBoolean = AtomicBoolean(false)
}

internal class BackgroundFlutterCoordinator(
    context: Context,
    private val handler: Handler = Handler(Looper.getMainLooper()),
) : BackgroundRefillRequester {
    private val applicationContext = context.applicationContext
    private var activeRequest: RhythmBackgroundRefillRequest? = null
    private var activeCompletion: BackgroundRefillCompletion? = null
    private var activeOnFinished: (() -> Unit)? = null
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private val finished = AtomicBoolean(false)
    private val timeout = Runnable { failAndFinish() }

    override fun requestRefill(
        request: RhythmBackgroundRefillRequest,
        completion: BackgroundRefillCompletion,
        onFinished: () -> Unit,
    ) {
        if (!RhythmHeadlessExecutionGate.busy.compareAndSet(false, true)) {
            completion.failed(request.expectedRevision)
            onFinished()
            return
        }
        activeRequest = request
        activeCompletion = completion
        activeOnFinished = onFinished
        try {
            startEngine()
            handler.postDelayed(timeout, BACKGROUND_TIMEOUT_MILLIS)
        } catch (_: Exception) {
            failAndFinish()
        }
    }

    private fun startEngine() {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "Background Flutter engine must start on the Android main thread."
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
                BACKGROUND_ENTRYPOINT_LIBRARY,
                BACKGROUND_ENTRYPOINT_FUNCTION,
            ),
        )
    }

    private fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                RhythmAlarmChannelContract.BACKGROUND_READY ->
                    result.success(requireActiveRequest().toChannelMap())
                RhythmAlarmChannelContract.COMPLETE_BACKGROUND_REFILL ->
                    completeRefill(call.arguments, result)
                RhythmAlarmChannelContract.BACKGROUND_REFILL_FAILED ->
                    reportRefillFailure(call.arguments, result)
                else -> result.notImplemented()
            }
        } catch (error: MalformedRhythmDeliveryStateException) {
            result.error("invalidPayload", error.message, null)
            failAndFinish()
        } catch (error: MalformedRhythmDeliveryPlanException) {
            result.error("invalidPayload", error.message, null)
            failAndFinish()
        } catch (_: Exception) {
            result.error("backgroundRefillFailed", "Background refill failed.", null)
            failAndFinish()
        }
    }

    private fun completeRefill(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val map = requireMap(arguments, "completeBackgroundRefill")
        val expectedRevision =
            requirePositiveLong(map["expectedRevision"], "expectedRevision")
        val request = requireActiveRequest()
        if (expectedRevision != request.expectedRevision) {
            throw MalformedRhythmDeliveryStateException(
                "Background refill revision does not match its request.",
            )
        }
        val replacement =
            RhythmDeliveryPlanChannelCodec.decodePlan(map["plan"], request.state.requestCode)
        val adopted =
            requireNotNull(activeCompletion).complete(
                expectedRevision = expectedRevision,
                observedAtEpochMillis = request.observedAtEpochMillis,
                replacement = replacement,
            )
        result.success(mapOf("adopted" to adopted))
        handler.post(::finish)
    }

    private fun reportRefillFailure(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val map = requireMap(arguments, "backgroundRefillFailed")
        val expectedRevisionValue = map["expectedRevision"]
        val expectedRevision =
            if (expectedRevisionValue == null) {
                requireActiveRequest().expectedRevision
            } else {
                requirePositiveLong(expectedRevisionValue, "expectedRevision")
            }
        requireNotNull(activeCompletion).failed(expectedRevision)
        result.success(null)
        handler.post(::finish)
    }

    private fun requireActiveRequest(): RhythmBackgroundRefillRequest =
        checkNotNull(activeRequest) { "No Android Rhythm refill is active." }

    private fun failAndFinish() {
        val request = activeRequest
        val completion = activeCompletion
        if (request != null && completion != null) {
            try {
                completion.failed(request.expectedRevision)
            } catch (_: Exception) {
                // The persisted queue remains the recovery source of truth.
            }
        }
        finish()
    }

    private fun finish() {
        if (!finished.compareAndSet(false, true)) {
            return
        }
        handler.removeCallbacks(timeout)
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
        activeRequest = null
        activeCompletion = null
        val onFinished = activeOnFinished
        activeOnFinished = null
        RhythmHeadlessExecutionGate.busy.set(false)
        onFinished?.invoke()
    }
}
