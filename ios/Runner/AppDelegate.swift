import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK
    GMSServices.provideAPIKey("AIzaSyDkRFkgfxFkrItRxPvGZgQZtvLzDgDRnwI")
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "phone_launcher", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "openURL" {
        if let args = call.arguments as? [String: Any],
           let urlString = args["url"] as? String,
           let url = URL(string: urlString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
              result(success)
            })
          } else {
            result(FlutterError(code: "UNAVAILABLE",
                              message: "Could not open URL",
                              details: nil))
          }
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                            message: "Invalid URL",
                            details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
