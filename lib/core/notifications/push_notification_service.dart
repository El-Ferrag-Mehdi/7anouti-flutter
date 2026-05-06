import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

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
  static const Duration _appleTokenRetryInterval = Duration(seconds: 5);
  static const int _maxAppleTokenRetryAttempts = 24;

  bool _initialized = false;
  bool _firebaseAvailable = false;
  bool _tokenSyncInProgress = false;
  AppLifecycleListener? _appLifecycleListener;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  Timer? _appleTokenRetryTimer;
  int _appleTokenRetryAttempts = 0;

  bool get _isApplePushPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
      _appLifecycleListener ??= AppLifecycleListener(
        onResume: () {
          unawaited(syncTokenWithBackend());
        },
      );
    } on Object catch (error, stackTrace) {
      debugPrint('FCM disabled (Firebase init failed): $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'FCM permission status (${defaultTargetPlatform.name}): '
      '${settings.authorizationStatus.name}',
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM disabled: notification permission denied.');
      return;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      final synced = await _syncCurrentTokenWithBackend(messaging);
      if (!synced && _isApplePushPlatform) {
        _startAppleTokenRetryLoop();
      }
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      final allowed = await _shouldDisplayNotification(message);
      if (!allowed) {
        debugPrint(
          'FCM notification ignored: not intended for current session.',
        );
        return;
      }

      unawaited(
        LocalNotificationService.instance.show(
          title: notification.title ?? '7anouti',
          body: notification.body ?? '',
        ),
      );
    });

    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
      unawaited(_handleTokenRefresh(token));
    });
  }

  Future<void> syncTokenWithBackend() async {
    if (!_firebaseAvailable) return;
    try {
      final synced = await _syncCurrentTokenWithBackend(
        FirebaseMessaging.instance,
      );
      if (!synced && _isApplePushPlatform) {
        _startAppleTokenRetryLoop();
      }
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> clearTokenOnBackend() async {
    try {
      final authToken = await TokenStorage.getToken();
      if (authToken == null || authToken.isEmpty) {
        return;
      }
      await ApiService().delete('/auth/fcm-token');
    } on ApiException catch (error) {
      if (error.message.contains('Session expiree')) {
        return;
      }
      debugPrint('FCM token clear failed: ${error.message}');
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token clear failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> clearDeviceTokenForLogout() async {
    await clearTokenOnBackend();
    if (!_firebaseAvailable) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } on Object catch (error, stackTrace) {
      debugPrint('FCM local token delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await TokenStorage.getToken();
      if (authToken == null || authToken.isEmpty) {
        return;
      }
      await ApiService().post(
        '/auth/fcm-token',
        body: {
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
      _stopAppleTokenRetryLoop();
      debugPrint(
        'FCM token uploaded on ${defaultTargetPlatform.name}: '
        '${_redactToken(token)}',
      );
    } on Object catch (error, stackTrace) {
      debugPrint('FCM token upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    await _sendTokenToBackend(token);
  }

  Future<bool> _syncCurrentTokenWithBackend(
    FirebaseMessaging messaging,
  ) async {
    if (_tokenSyncInProgress) return false;
    _tokenSyncInProgress = true;
    try {
      final token = await _getTokenForCurrentPlatform(messaging);
      if (token == null || token.isEmpty) {
        debugPrint('FCM token unavailable on ${defaultTargetPlatform.name}.');
        return false;
      }

      debugPrint('FCM token acquired on ${defaultTargetPlatform.name}.');
      await _sendTokenToBackend(token);
      return true;
    } finally {
      _tokenSyncInProgress = false;
    }
  }

  Future<String?> _getTokenForCurrentPlatform(
    FirebaseMessaging messaging,
  ) async {
    if (_isApplePushPlatform) {
      final apnsToken = await _waitForApnsToken(messaging);
      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint(
          'APNs token unavailable on ${defaultTargetPlatform.name}; '
          'FCM token sync postponed.',
        );
        return null;
      }
    }

    return messaging.getToken();
  }

  void _startAppleTokenRetryLoop() {
    if (!_isApplePushPlatform || _appleTokenRetryTimer != null) {
      return;
    }

    _appleTokenRetryAttempts = 0;
    _appleTokenRetryTimer = Timer.periodic(_appleTokenRetryInterval, (timer) {
      unawaited(_retryAppleTokenSyncTick());
    });
    debugPrint(
      'Starting APNs token retry loop on ${defaultTargetPlatform.name}.',
    );
  }

  Future<void> _retryAppleTokenSyncTick() async {
    if (_tokenSyncInProgress) return;

    _appleTokenRetryAttempts += 1;
    final synced = await _syncCurrentTokenWithBackend(
      FirebaseMessaging.instance,
    );
    if (synced) {
      return;
    }

    if (_appleTokenRetryAttempts >= _maxAppleTokenRetryAttempts) {
      debugPrint(
        'Stopping APNs token retry loop after '
        '$_appleTokenRetryAttempts attempts.',
      );
      _stopAppleTokenRetryLoop();
    }
  }

  void _stopAppleTokenRetryLoop() {
    _appleTokenRetryTimer?.cancel();
    _appleTokenRetryTimer = null;
    _appleTokenRetryAttempts = 0;
  }

  String _redactToken(String token) {
    if (token.length <= 8) return token;
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 1; attempt <= 10; attempt++) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        if (attempt > 1) {
          debugPrint(
            'APNs token acquired on attempt $attempt '
            '(${defaultTargetPlatform.name}).',
          );
        }
        return apnsToken;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return null;
  }

  Future<bool> _shouldDisplayNotification(RemoteMessage message) async {
    final currentUserId = await TokenStorage.getUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final data = message.data;
    final singleRecipient = (data['recipientUserId'] as String?)?.trim();
    if (singleRecipient != null && singleRecipient.isNotEmpty) {
      return singleRecipient == currentUserId;
    }

    final recipientsRaw = (data['recipientUserIds'] as String?)?.trim();
    if (recipientsRaw == null || recipientsRaw.isEmpty) {
      return true;
    }

    try {
      final decoded = jsonDecode(recipientsRaw);
      if (decoded is! List) return true;
      final recipients = decoded
          .map(
            (value) => value?.toString().trim(),
          )
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet();
      if (recipients.isEmpty) return true;
      return recipients.contains(currentUserId);
    } on Object {
      return true;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    _appLifecycleListener?.dispose();
    _stopAppleTokenRetryLoop();
    _appLifecycleListener = null;
    _tokenRefreshSub = null;
    _onMessageSub = null;
  }
}
