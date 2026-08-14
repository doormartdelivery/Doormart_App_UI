package com.example.doormartdelivery

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "doormart/location")
            .setMethodCallHandler { call, result ->
                if (call.method != "getCurrentLocation") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fineGranted = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
                val coarseGranted = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED

                if (!fineGranted && !coarseGranted) {
                    result.error("PERMISSION_DENIED", "Location permission not granted", null)
                    return@setMethodCallHandler
                }

                val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                val location =
                    locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                        ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

                if (location == null) {
                    result.error("UNAVAILABLE", "Unable to determine current location", null)
                    return@setMethodCallHandler
                }

                result.success(
                    mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                    ),
                )
            }
    }
}
