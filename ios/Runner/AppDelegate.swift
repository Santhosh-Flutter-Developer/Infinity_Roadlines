import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by google_maps_flutter on iOS. Must be called before Flutter/GoogleMaps
    // is used, or the map will fail to render (and can crash) at runtime.
    GMSServices.provideAPIKey("AIzaSyDlDoDtlSG5pxOpWQ2KrS6xjYjfqMmCyEs")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}