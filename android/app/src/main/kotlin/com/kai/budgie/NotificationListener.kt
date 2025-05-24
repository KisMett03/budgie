package com.kai.budgie

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class NotificationListener : NotificationListenerService() {
    companion object {
        private const val TAG = "NotificationListener"
        private var instance: NotificationListener? = null
        
        fun getInstance(): NotificationListener? {
            return instance
        }
    }

    private var methodChannel: MethodChannel? = null
    private var isListening = false

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "NotificationListener service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "NotificationListener service destroyed")
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }

    fun startListening() {
        isListening = true
        Log.d(TAG, "Started listening for notifications")
    }

    fun stopListening() {
        isListening = false
        Log.d(TAG, "Stopped listening for notifications")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (!isListening || sbn == null || methodChannel == null) return

        try {
            val notification = sbn.notification
            val packageName = sbn.packageName
            val extras = notification.extras

            // Extract notification data
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val content = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            
            // Use big text if available, otherwise use regular content
            val notificationContent = if (bigText.isNotEmpty()) bigText else content

            // Skip empty notifications
            if (title.isEmpty() && notificationContent.isEmpty()) return

            // Skip system notifications
            if (isSystemApp(packageName)) return

            Log.d(TAG, "Notification received from $packageName: $title - $notificationContent")

            // Prepare data to send to Flutter
            val notificationData = hashMapOf<String, Any>(
                "title" to title,
                "content" to notificationContent,
                "packageName" to packageName,
                "timestamp" to System.currentTimeMillis()
            )

            // Send to Flutter
            methodChannel?.invokeMethod("onNotificationReceived", notificationData)

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // We don't need to handle removed notifications for our use case
    }

    private fun isSystemApp(packageName: String): Boolean {
        // Filter out system apps and common non-payment apps
        val systemPackages = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.google.android.gms",
            "com.android.providers.downloads",
            "com.android.chrome",
            "com.facebook.katana",
            "com.instagram.android",
            "com.twitter.android",
            "com.whatsapp",
            "com.telegram.messenger"
        )
        
        return systemPackages.contains(packageName) || packageName.startsWith("com.android.")
    }
} 