package com.bmsecurity.bm.workers

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.bmsecurity.bm.MainActivity
import com.bmsecurity.bm.R
import com.google.android.gms.location.*
import com.google.gson.Gson
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.util.concurrent.TimeUnit

class LocationWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    private val TAG = "LocationWorker"
    private val locationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(applicationContext)
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val gson = Gson()

    @SuppressLint("MissingPermission")
    override suspend fun doWork(): Result {
        Log.d(TAG, "Location worker started")

        // Show foreground notification
        val notification = createNotification("Tracking your location")
        setForeground(createForegroundInfo(notification))

        try {
            // Get last known location
            val lastLocation = getLastKnownLocation()
            lastLocation?.let { location ->
                sendLocationToServer(location)
            }

            // Request location updates
            val locationResult = requestLocationUpdates()
            sendLocationToServer(locationResult)


            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in location worker", e)
            return Result.retry()
        }
    }

    private suspend fun getLastKnownLocation(): Location? {
        return try {
            locationClient.lastLocation.await()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last location", e)
            null
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun requestLocationUpdates(): Location {
        val locationRequest = LocationRequest.create().apply {
            interval = TimeUnit.MINUTES.toMillis(15)
            fastestInterval = TimeUnit.MINUTES.toMillis(5)
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }

        return suspendCancellableCoroutine { continuation ->
            locationClient.requestLocationUpdates(
                locationRequest,
                object : LocationCallback() {
                    override fun onLocationResult(locationResult: LocationResult) {
                        locationResult.lastLocation?.let { location ->
                            if (!continuation.isCompleted) {
                                continuation.resume(location, null)
                            }
                        }
                    }
                },
                Looper.getMainLooper()
            )
        }
    }

    private suspend fun sendLocationToServer(location: Location) {
        val sharedPrefs = applicationContext.getSharedPreferences("bm_security", Context.MODE_PRIVATE)
        val requestId = sharedPrefs.getLong("current_request_id", -1)
        val authToken = sharedPrefs.getString("auth_token", "")

        if (requestId == -1L || authToken.isNullOrEmpty()) {
            Log.e(TAG, "Missing request ID or auth token")
            return
        }

        val client = OkHttpClient()
        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = """
            {
                "requestId": $requestId,
                "latitude": ${location.latitude},
                "longitude": ${location.longitude}
            }
        """.trimIndent().toRequestBody(mediaType)

        val request = Request.Builder()
            .url("YOUR_API_BASE_URL/api/locations")
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer $authToken")
            .post(requestBody)
            .build()

        try {
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) {
                Log.e(TAG, "Failed to send location: ${response.code} - ${response.body?.string()}")
            } else {
                Log.d(TAG, "Location sent successfully")
            }
        } catch (e: IOException) {
            Log.e(TAG, "Error sending location", e)
        }
    }

    private fun createNotification(contentText: String): Notification {
        createNotificationChannel()

        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle("BM Security")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createForegroundInfo(notification: Notification): ForegroundInfo {
        return ForegroundInfo(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks your location in the background"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    companion object {
        private const val CHANNEL_ID = "location_service"
        private const val NOTIFICATION_ID = 1001
    }
}