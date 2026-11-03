import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets the background engine iOS spins up for a notification action (e.g.
    // chat "Reply") register plugins correctly — without this, plugins used
    // inside notificationBackgroundHandler (push_service.dart) may not work
    // when the app isn't already running.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: self)

    // Ask iOS for an APNs device token. firebase_messaging's requestPermission()
    // is documented to do this, but on this app it never fires either
    // didRegisterForRemoteNotifications* callback — apsd shows no listening
    // topics for our bundle id, so no registration is ever attempted, and
    // Messaging.apnsToken stays nil forever (hence no FCM token, hence no
    // `device_tokens` row, hence no push on iOS). Calling it directly is
    // idempotent and safe even if the plugin also calls it.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
