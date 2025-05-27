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
        
        // Queue for storing notifications when channel is not ready
        private val pendingNotifications = mutableListOf<Map<String, Any>>()
        
        // Maximum queue size to prevent memory issues
        private const val MAX_QUEUE_SIZE = 20
        
        fun getInstance(): NotificationListener? {
            return instance
        }
        
        // Add a notification to the pending queue
        fun addToPendingQueue(notification: Map<String, Any>) {
            synchronized(pendingNotifications) {
                // If queue is full, remove oldest items
                while (pendingNotifications.size >= MAX_QUEUE_SIZE) {
                    pendingNotifications.removeAt(0)
                }
                pendingNotifications.add(notification)
                Log.d(TAG, "Added notification to pending queue. Queue size: ${pendingNotifications.size}")
            }
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
        Log.d(TAG, "Method channel set for notification listener")
        
        // Process any pending notifications that were received before the channel was ready
        processPendingNotifications()
    }
    
    // Process all pending notifications from the queue
    private fun processPendingNotifications() {
        synchronized(pendingNotifications) {
            if (pendingNotifications.isNotEmpty() && methodChannel != null) {
                Log.d(TAG, "Processing ${pendingNotifications.size} pending notifications")
                pendingNotifications.forEach { data ->
                    try {
                        methodChannel?.invokeMethod("onNotificationReceived", data)
                        Log.d(TAG, "Sent pending notification to Flutter: ${data["title"]} - ${data["content"]}")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error sending pending notification to Flutter", e)
                    }
                }
                pendingNotifications.clear()
                Log.d(TAG, "Pending notification queue cleared")
            }
        }
    }

    fun startListening() {
        isListening = true
        Log.d(TAG, "Started listening for notifications")
        
        // Process any pending notifications when listening starts
        processPendingNotifications()
    }

    fun stopListening() {
        isListening = false
        Log.d(TAG, "Stopped listening for notifications")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) {
            Log.d(TAG, "Received null notification, ignoring")
            return
        }
        
        val packageName = sbn.packageName
        
        // Always process notifications from our own app, regardless of isListening flag
        val isOwnApp = packageName == "com.kai.budgie"
        
        if (isOwnApp) {
            Log.d(TAG, "Received notification from our own app - processing regardless of listener state")
        } else if (!isListening) {
            Log.d(TAG, "Ignoring notification from $packageName because listener is not active")
            return
        }

        try {
            val notification = sbn.notification
            val extras = notification.extras

            // Extract notification data
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val content = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            
            // Use big text if available, otherwise use regular content
            val notificationContent = if (bigText.isNotEmpty()) bigText else content

            // Skip empty notifications
            if (title.isEmpty() && notificationContent.isEmpty()) {
                Log.d(TAG, "Empty notification, ignoring")
                return
            }

            // Skip system notifications (except for our own app)
            if (!isOwnApp && isSystemApp(packageName)) {
                Log.d(TAG, "System notification from $packageName, ignoring")
                return
            }

            Log.d(TAG, "Processing notification from $packageName: $title - $notificationContent")

            // Prepare data to send to Flutter
            val notificationData = hashMapOf<String, Any>(
                "title" to title,
                "content" to notificationContent,
                "packageName" to packageName,
                "timestamp" to System.currentTimeMillis()
            )

            // Send to Flutter if channel is available, otherwise store for later
            if (methodChannel != null) {
                try {
                    if (isOwnApp) {
                        Log.d(TAG, "Sending our app's notification to Flutter via method channel")
                    }
                    methodChannel?.invokeMethod("onNotificationReceived", notificationData)
                    Log.d(TAG, "Notification sent to Flutter")
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending notification to Flutter, adding to pending queue", e)
                    addToPendingQueue(notificationData)
                }
            } else {
                Log.d(TAG, "Method channel is null, storing notification for later processing")
                addToPendingQueue(notificationData)
                
                if (isOwnApp) {
                    Log.e(TAG, "WARNING: Method channel is null when processing our own app's notification. This indicates an initialization issue.")
                }
            }

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
        
        // Don't filter out our own app's notifications for testing
        if (packageName == "com.kai.budgie") {
            return false
        }
        
        return systemPackages.contains(packageName) || packageName.startsWith("com.android.")
    }
} 