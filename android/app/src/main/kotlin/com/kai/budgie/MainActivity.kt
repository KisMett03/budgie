package com.kai.budgie

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kai.budgie/notification_listener"
    private var notificationListener: NotificationListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationAccess" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "requestNotificationAccess" -> {
                    requestNotificationAccess()
                    result.success(null)
                }
                "startListening" -> {
                    startNotificationListener()
                    result.success(null)
                }
                "stopListening" -> {
                    stopNotificationListener()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Initialize notification listener
        notificationListener = NotificationListener.getInstance()
        notificationListener?.setMethodChannel(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL))
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val componentName = name.split("/").toTypedArray()
                if (componentName.size == 2 && componentName[0] == packageName) {
                    return true
                }
            }
        }
        return false
    }

    private fun requestNotificationAccess() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun startNotificationListener() {
        notificationListener?.startListening()
    }

    private fun stopNotificationListener() {
        notificationListener?.stopListening()
    }
}
