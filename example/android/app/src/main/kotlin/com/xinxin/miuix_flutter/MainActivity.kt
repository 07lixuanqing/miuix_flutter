package com.xinxin.miuix_flutter

import android.annotation.SuppressLint
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private companion object {
        const val DYNAMIC_COLOR_CHANNEL = "miuix_flutter/platform_dynamic_color"
    }

    /**
     * Keeps Flutter's page surface continuous through both Android system bars.
     *
     * Dart requests edge-to-edge before the first application frame, but the
     * Android window exists earlier than that request. Configuring the decor at
     * creation time prevents a launch-frame status-bar strip and prevents the
     * gesture-navigation region from falling back to an opaque system color.
     * Navigation components still consume WindowInsets in Flutter, so icons,
     * labels, and the floating capsule never collide with the gesture handle.
     */
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DYNAMIC_COLOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemPalette" -> result.success(readSystemPalette())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Mirrors MIUIX DynamicColors.android.kt without adding a Flutter plugin
     * that applies an obsolete Kotlin Gradle plugin to the Android build.
     */
    @SuppressLint("InlinedApi", "UseKtx")
    private fun readSystemPalette(): Map<String, Any>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val raw = Settings.Secure.getString(
                    contentResolver,
                    "theme_customization_overlay_packages",
                )
                if (!raw.isNullOrBlank()) {
                    val json = JSONObject(raw)
                    val hex = json.optString("android.theme.customization.system_palette", "")
                    val seed = if (hex.isNotBlank()) {
                        Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
                    } else {
                        resources.getColor(android.R.color.system_accent1_500, theme)
                    }
                    return mapOf(
                        "seed" to (seed.toLong() and 0xffffffffL),
                        "style" to json.optString(
                            "android.theme.customization.theme_style",
                            "TONAL_SPOT",
                        ),
                        "spec" to if (Build.VERSION.SDK_INT >= 36) 2025 else 2021,
                    )
                }
            } catch (_: Exception) {
                // Fall through to the direct system-role mapping below.
            }
        }

        // Android 12/12L and Android 13+ devices without secure theme metadata
        // follow DynamicColors.android.kt's direct five-family role mapping.
        return mapOf(
            "sdk" to Build.VERSION.SDK_INT,
            "systemPalette" to readSystemColorFamilies(),
        )
    }

    /** Returns every system tone consumed by MIUIX's Android role mapping. */
    @SuppressLint("DiscouragedApi", "UseKtx")
    private fun readSystemColorFamilies(): Map<String, Any> {
        val tones = listOf(0, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000)

        fun family(name: String): List<Long> = tones.map { tone ->
            val resourceId = resources.getIdentifier(
                "system_${name}_$tone",
                "color",
                "android",
            )
            (resources.getColor(resourceId, theme).toLong() and 0xffffffffL)
        }

        return mapOf(
            "tones" to tones,
            "accent1" to family("accent1"),
            "accent2" to family("accent2"),
            "accent3" to family("accent3"),
            "neutral1" to family("neutral1"),
            "neutral2" to family("neutral2"),
        )
    }
}
