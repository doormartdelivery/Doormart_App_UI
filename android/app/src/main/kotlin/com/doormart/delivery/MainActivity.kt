package com.doormart.delivery

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

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

                val lastKnown = try {
                    locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                        ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                } catch (e: SecurityException) {
                    null
                }

                val fineCriteria = Criteria().apply {
                    accuracy = Criteria.ACCURACY_FINE
                }
                val bestProvider = locationManager.getBestProvider(fineCriteria, true)
                    ?: locationManager.getBestProvider(Criteria(), true)

                if (bestProvider == null) {
                    if (lastKnown != null) {
                        result.success(
                            mapOf(
                                "latitude" to lastKnown.latitude,
                                "longitude" to lastKnown.longitude,
                            ),
                        )
                    } else {
                        result.error("UNAVAILABLE", "Unable to determine current location", null)
                    }
                    return@setMethodCallHandler
                }

                val delivered = AtomicBoolean(false)
                val listener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        if (!delivered.compareAndSet(false, true)) return
                        locationManager.removeUpdates(this)
                        result.success(
                            mapOf(
                                "latitude" to location.latitude,
                                "longitude" to location.longitude,
                            ),
                        )
                    }

                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}

                    @Deprecated("Deprecated in Java")
                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                }

                try {
                    locationManager.requestLocationUpdates(
                        bestProvider,
                        0L,
                        0f,
                        listener,
                        Looper.getMainLooper(),
                    )
                    Handler(Looper.getMainLooper()).postDelayed({
                        if (!delivered.compareAndSet(false, true)) return@postDelayed
                        locationManager.removeUpdates(listener)
                        if (lastKnown != null) {
                            result.success(
                                mapOf(
                                    "latitude" to lastKnown.latitude,
                                    "longitude" to lastKnown.longitude,
                                ),
                            )
                        } else {
                            result.error("UNAVAILABLE", "Unable to determine current location", null)
                        }
                    }, 10000)
                } catch (e: SecurityException) {
                    if (lastKnown != null) {
                        result.success(
                            mapOf(
                                "latitude" to lastKnown.latitude,
                                "longitude" to lastKnown.longitude,
                            ),
                        )
                    } else {
                        result.error("UNAVAILABLE", e.message ?: "Unable to determine current location", null)
                    }
                }
            }
    }
}
