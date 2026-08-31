package com.xinxin.flutter_miuix

import android.app.Activity
import android.content.Context
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Native Android bridge for the MIUIX haptic roles used by the Dart widgets. */
class FlutterMiuixPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private lateinit var hapticChannel: MethodChannel
    private lateinit var accessibilityChannel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        hapticChannel = MethodChannel(binding.binaryMessenger, HAPTIC_CHANNEL)
        accessibilityChannel = MethodChannel(binding.binaryMessenger, ACCESSIBILITY_CHANNEL)
        hapticChannel.setMethodCallHandler(this)
        accessibilityChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        hapticChannel.setMethodCallHandler(null)
        accessibilityChannel.setMethodCallHandler(null)
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "performHapticFeedback" -> performHapticFeedback(call, result)
            "recommendedTimeoutMillis" -> recommendedTimeoutMillis(call, result)
            else -> result.notImplemented()
        }
    }

    /** Performs the platform haptic role requested by a Dart component. */
    private fun performHapticFeedback(call: MethodCall, result: MethodChannel.Result) {
        val hostView = activity?.window?.decorView
        if (hostView == null) {
            result.success(false)
            return
        }

        val role = call.argument<String>("type")
        result.success(hostView.performHapticFeedback(resolveHapticConstant(role)))
    }

    /** Mirrors Compose AccessibilityManager.calculateRecommendedTimeoutMillis. */
    private fun recommendedTimeoutMillis(call: MethodCall, result: MethodChannel.Result) {
        val requested = call.argument<Number>("originalTimeoutMillis")?.toLong()
        if (requested == null || requested <= 0L) {
            result.error("invalid_timeout", "originalTimeoutMillis must be positive", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(requested)
            return
        }
        val manager = applicationContext
            ?.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
        if (manager == null) {
            result.success(requested)
            return
        }
        var flags = AccessibilityManager.FLAG_CONTENT_ICONS or
            AccessibilityManager.FLAG_CONTENT_TEXT
        if (call.argument<Boolean>("hasAction") == true) {
            flags = flags or AccessibilityManager.FLAG_CONTENT_CONTROLS
        }
        val platformInput = requested.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        result.success(manager.getRecommendedTimeoutMillis(platformInput, flags).toLong())
    }

    /** Maps every public Dart haptic role to the closest Android platform role. */
    @Suppress("DEPRECATION")
    private fun resolveHapticConstant(role: String?): Int = when (role) {
        "contextClick" -> HapticFeedbackConstants.CONTEXT_CLICK
        "toggleOn" -> if (Build.VERSION.SDK_INT >= 34) {
            HapticFeedbackConstants.TOGGLE_ON
        } else {
            HapticFeedbackConstants.CONTEXT_CLICK
        }
        "toggleOff" -> if (Build.VERSION.SDK_INT >= 34) {
            HapticFeedbackConstants.TOGGLE_OFF
        } else {
            HapticFeedbackConstants.CONTEXT_CLICK
        }
        "segmentTick" -> if (Build.VERSION.SDK_INT >= 34) {
            HapticFeedbackConstants.SEGMENT_TICK
        } else {
            HapticFeedbackConstants.CLOCK_TICK
        }
        "gestureThresholdActivate" -> if (Build.VERSION.SDK_INT >= 34) {
            HapticFeedbackConstants.GESTURE_THRESHOLD_ACTIVATE
        } else {
            HapticFeedbackConstants.CONTEXT_CLICK
        }
        "confirm" -> if (Build.VERSION.SDK_INT >= 30) {
            HapticFeedbackConstants.CONFIRM
        } else {
            HapticFeedbackConstants.CONTEXT_CLICK
        }
        "textHandleMove" -> if (Build.VERSION.SDK_INT >= 27) {
            HapticFeedbackConstants.TEXT_HANDLE_MOVE
        } else {
            HapticFeedbackConstants.CLOCK_TICK
        }
        else -> HapticFeedbackConstants.CONTEXT_CLICK
    }

    private companion object {
        const val HAPTIC_CHANNEL = "flutter_miuix/haptics"
        const val ACCESSIBILITY_CHANNEL = "flutter_miuix/accessibility"
    }
}
