import Flutter
import CoreLocation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var pendingLocationResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let handled = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupLocationChannel()
    return handled
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupLocationChannel() {
    guard
      let controller = window?.rootViewController as? FlutterViewController
    else { return }

    let channel = FlutterMethodChannel(
      name: "doormart/location",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getCurrentLocation" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.requestCurrentLocation(result: result)
    }
  }

  private func requestCurrentLocation(result: @escaping FlutterResult) {
    if CLLocationManager.locationServicesEnabled() == false {
      result(FlutterError(code: "UNAVAILABLE", message: "Location services are disabled", details: nil))
      return
    }

    let manager = locationManager ?? CLLocationManager()
    locationManager = manager
    manager.delegate = self
    pendingLocationResult = result

    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    switch status {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .restricted, .denied:
      pendingLocationResult = nil
      result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission not granted", details: nil))
    default:
      manager.requestLocation()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if let result = pendingLocationResult {
      let status: CLAuthorizationStatus
      if #available(iOS 14.0, *) {
        status = manager.authorizationStatus
      } else {
        status = CLLocationManager.authorizationStatus()
      }
      if status == .authorizedAlways || status == .authorizedWhenInUse {
        manager.requestLocation()
      } else if status == .denied || status == .restricted {
        pendingLocationResult = nil
        result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission not granted", details: nil))
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let result = pendingLocationResult, let location = locations.last else { return }
    pendingLocationResult = nil
    result([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard let result = pendingLocationResult else { return }
    pendingLocationResult = nil
    result(FlutterError(code: "UNAVAILABLE", message: error.localizedDescription, details: nil))
  }
}
