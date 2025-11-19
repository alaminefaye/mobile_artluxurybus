import Flutter
import UIKit
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurer Firebase
    FirebaseApp.configure()
    
    // Définir le délégué Firebase Messaging
    Messaging.messaging().delegate = self
    
    // Demander les permissions pour les notifications
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if granted {
          print("✅ Permissions notifications accordées")
        } else {
          print("❌ Permissions notifications refusées: \(error?.localizedDescription ?? "unknown")")
        }
      }
    )
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Callback pour le token APNs
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("✅ Token APNs reçu: \(token)")
    
    // ⚠️ IMPORTANT: Transmettre le token APNs à Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("✅ Token APNs transmis à Firebase")
  }
  
  // Callback en cas d'erreur
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Erreur enregistrement notifications: \(error.localizedDescription)")
  }
  
  // Gestion des notifications en arrière-plan
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📬 Notification reçue: \(userInfo)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}

// Extension pour implémenter le délégué Firebase Messaging
extension AppDelegate: MessagingDelegate {
  // Appelé quand Firebase génère un nouveau token FCM
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let token = fcmToken {
      print("🔥 Token FCM généré: \(token)")
      print("💾 Token FCM disponible pour l'enregistrement")
    } else {
      print("⚠️ Token FCM est nil")
    }
  }
}
