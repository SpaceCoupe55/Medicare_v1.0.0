import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Manages FCM token registration for the current user.
/// Call [init] once after the user's Firestore profile is confirmed.
class FcmService {
  static const _vapidKey =
      'BNU1fYM8UFcTHYso7VM6Fj4FknM2qsjGyFUNuXsYb2HVY7Vw7-NT_OlrCk0H4c3Rfonc6F7in61uLbSx8r086rg';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Requests notification permission, retrieves the FCM token, and saves it
  /// to `users/{uid}.fcmToken` in Firestore.
  Future<void> init(String uid) async {
    // Permission request (required on iOS/macOS; no-op on Android/Web grant)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    try {
      final token = kIsWeb
          ? await _fcm.getToken(vapidKey: _vapidKey)
          : await _fcm.getToken();

      if (token == null) return;

      await _db.collection('users').doc(uid).update({'fcmToken': token});
    } catch (e) {
      // Non-fatal — the app works without push; in-app notifications still work.
      if (kDebugMode) debugPrint('[FcmService] token fetch failed: $e');
    }

    // Refresh token whenever FCM rotates it
    _fcm.onTokenRefresh.listen((newToken) async {
      try {
        await _db.collection('users').doc(uid).update({'fcmToken': newToken});
      } catch (_) {}
    });
  }

  /// Clears the FCM token from Firestore on sign-out so stale tokens
  /// don't receive notifications for a logged-out session.
  Future<void> clearToken(String uid) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
  }
}
