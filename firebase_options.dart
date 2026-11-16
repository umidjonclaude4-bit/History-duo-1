import 'package:firebase_core/firebase_core.dart';

/// Firebase konsolidan olingan qiymatlarni shu yerga yozing.
/// (google-services.json ichida: current_key, mobilesdk_app_id,
/// project_number, project_id)
class AppFirebaseOptions {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'YOUR_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'YOUR_APP_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: 'YOUR_PROJECT_NUMBER');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'YOUR_PROJECT_ID');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      !apiKey.startsWith('YOUR_');

  static const options = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
  );
}
