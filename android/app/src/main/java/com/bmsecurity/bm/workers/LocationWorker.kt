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
import java.net.HttpURLConnection
import java.net.URL
import java.io.OutputStreamWriter
import org.json.JSONObject

class LocationWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val TAG = "LocationWorker"
    private val locationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(applicationContext)
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val gson = Gson()

    @SuppressLint("MissingPermission")
    override suspend fun doWork(): Result {
        Log.d(TAG, "Location worker started")

        try {
            // Show foreground notification
            val notification = createNotification("Tracking your location")
            setForeground(createForegroundInfo(notification))

            // Get last known location
            val lastLocation = getLastKnownLocation()
            if (lastLocation != null) {
                Log.d(TAG, "Got last known location: ${lastLocation.latitude}, ${lastLocation.longitude}")
                sendLocationToServer(lastLocation)
            } else {
                Log.w(TAG, "No last known location available")
            }

            // Request location updates
            val locationResult = requestLocationUpdates()
            if (locationResult != null) {
                Log.d(TAG, "Got new location: ${locationResult.latitude}, ${locationResult.longitude}")
                sendLocationToServer(locationResult)
            } else {
                Log.w(TAG, "Failed to get new location")
            }

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

    private suspend fun requestLocationUpdates(): Location? {
        return try {
            locationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null).await()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current location", e)
            null
        }
    }

    private suspend fun sendLocationToServer(location: Location) {
        try {
            // Get stored request ID and auth token
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val requestId = prefs.getString("flutter.current_tracking_request", null)
            val authToken = prefs.getString("flutter.auth_token", null)
            val baseUrl = prefs.getString("flutter.base_url", "http://192.168.100.10:5000")

            if (requestId == null || authToken == null) {
                Log.e(TAG, "Missing request ID or auth token")
                return
            }

            val url = URL("$baseUrl/api/locations")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Authorization", "Bearer $authToken")
            connection.doOutput = true

            val jsonBody = JSONObject().apply {
                put("requestId", requestId)
                put("latitude", location.latitude)
                put("longitude", location.longitude)
            }

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(jsonBody.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_CREATED) {
                Log.d(TAG, "Location sent successfully")
            } else {
                Log.e(TAG, "Failed to send location: $responseCode")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending location to server", e)
        }
    }

    private fun createNotification(message: String): Notification {
        val channelId = "location_service"
        val channelName = "Location Service"
        val importance = NotificationManager.IMPORTANCE_LOW

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Used for tracking location in background"
            }
            notificationManager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(context, channelId)
            .setContentTitle("BM Security")
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createForegroundInfo(notification: Notification): ForegroundInfo {
        return ForegroundInfo(NOTIFICATION_ID, notification)
    }

    companion object {
        private const val NOTIFICATION_ID = 1001
    }
}