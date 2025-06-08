package com.bmsecurity.bm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.work.*
import com.bmsecurity.bm.workers.LocationWorker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bmsecurity.bm/background"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "initializeService" -> {
                    try {
                        initializeWorkManager()
                        result.success("Background service initialized")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to initialize background service", e.toString())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Location Service"
            val descriptionText = "Used for tracking location in background"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel("location_service", name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initializeWorkManager() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(false)
            .setRequiresCharging(false)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<LocationWorker>(
            15, TimeUnit.MINUTES,
            5, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(applicationContext)
            .enqueueUniquePeriodicWork(
                "location_work",
                ExistingPeriodicWorkPolicy.REPLACE,
                workRequest
            )
    }
}