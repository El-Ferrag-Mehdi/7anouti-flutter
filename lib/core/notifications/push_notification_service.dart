import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on Object {
    // Ignore: Firebase may be unavailable on environments not configured yet.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _firebaseAvailable = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // TODO(ios): Re-enable when Apple Developer account/APNs is configured.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('FCM iOS is temporarily disabled.');
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
    } on Object catch (error, stackTrace) {
      debugPrint('FCM disabled (Firebase init failed): $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      unawaited(
        LocalNotificationService.instance.show(
          title: notification.title ?? '7anouti',
          body: notification.body ?? '',
        ),
      );
    });

    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
      unawaited(_sendTokenToBackend(token));
    });
  }

  Future<void> syncTokenWithBackend() async {
    if (!_firebaseAvailable) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _sendTokenToBackend(token);
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> clearTokenOnBackend() async {
    try {
      await ApiService().delete('/auth/fcm-token');
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token clear failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiService().post(
        '/auth/fcm-token',
        body: {'token': token},
      );
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
  }
}
