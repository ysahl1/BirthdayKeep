package com.ysahl1.birthdaykeep

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.fingerprint.FingerprintManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth braucht eine FragmentActivity, sonst schlägt die App-Sperre fehl
class MainActivity : FlutterFragmentActivity() {
    private var homeChannel: MethodChannel? = null
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingAction = intent?.getStringExtra(BirthdayActions.EXTRA)
        super.onCreate(savedInstanceState)
    }

    // Läuft die App schon, kommt die Aktion von Widget oder Kachel hier an
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.getStringExtra(BirthdayActions.EXTRA) ?: return
        pendingAction = action
        homeChannel?.invokeMethod("actionAvailable", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "birthdaykeep/home").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePendingAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    "getAppIcon" -> result.success(currentAppIcon())
                    "setAppIcon" -> {
                        setAppIcon(call.arguments as String)
                        result.success(null)
                    }
                    "playSaveSound" -> {
                        playSaveSound()
                        result.success(null)
                    }
                    "refreshWidgets" -> {
                        BirthdayWidget.refreshAll(this@MainActivity)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
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

    private val appIcons = mapOf(
        "cake" to "IconCake",
        "balloons" to "IconBalloons",
        "calendar" to "IconCalendar",
        "cupcake" to "IconCupcake",
    )

    private fun aliasName(alias: String) = ComponentName(this, "$packageName.$alias")

    private fun currentAppIcon(): String {
        for ((icon, alias) in appIcons) {
            val state = packageManager.getComponentEnabledSetting(aliasName(alias))
            val enabled = state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && icon == "cake")
            if (enabled) return icon
        }
        return "cake"
    }

    // Erst das neue Icon aktivieren, dann die anderen abschalten, damit die App
    // nie ganz aus dem Launcher verschwindet
    private fun setAppIcon(icon: String) {
        val target = appIcons[icon] ?: return
        packageManager.setComponentEnabledSetting(
            aliasName(target),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (alias in appIcons.values) {
            if (alias == target) continue
            packageManager.setComponentEnabledSetting(
                aliasName(alias),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    // Nur im normalen Klingelmodus, im Lautlos- oder Vibrationsmodus bleibt es still
    private fun playSaveSound() {
        val audio = getSystemService(AudioManager::class.java) ?: return
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val player = MediaPlayer.create(this, R.raw.save_chime, attributes, audio.generateAudioSessionId()) ?: return
        player.setOnCompletionListener { it.release() }
        player.start()
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
