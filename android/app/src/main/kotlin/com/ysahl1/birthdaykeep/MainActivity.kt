package com.ysahl1.birthdaykeep

import android.content.pm.PackageManager
import android.hardware.fingerprint.FingerprintManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth braucht eine FragmentActivity, sonst schlägt die App-Sperre fehl
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // local_auth meldet auf Android nur "stark" oder "schwach", nicht ob
        // das Gerät einen Fingerabdruck oder ein Gesicht erkennt
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "birthdaykeep/biometrics")
            .setMethodCallHandler { call, result ->
                if (call.method == "getOptions") {
                    result.success(
                        mapOf(
                            "fingerprint" to hasEnrolledFingerprint(),
                            "face" to hasFaceHardware(),
                        ),
                    )
                } else if (call.method == "setScreenProtection") {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun hasEnrolledFingerprint(): Boolean {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) return false
        return getSystemService(FingerprintManager::class.java)?.hasEnrolledFingerprints() == true
    }

    private fun hasFaceHardware(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)
}
