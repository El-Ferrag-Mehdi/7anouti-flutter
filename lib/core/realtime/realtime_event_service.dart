import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sevenouti/config/env.dart';
import 'package:sevenouti/core/auth/token_refresh_service.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.payload,
    required this.rawEventName,
  });

  final String type;
  final Map<String, dynamic> payload;
  final String rawEventName;
}

class RealtimeEventService {
  RealtimeEventService();

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;

  bool _running = false;
  bool _disposed = false;
  http.Client? _activeClient;

  Future<void> start() async {
    if (_disposed || _running) return;
    _running = true;
    unawaited(_runLoop());
  }

  Future<void> stop() async {
    _running = false;
    _activeClient?.close();
    _activeClient = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _controller.close();
  }

  Future<void> _runLoop() async {
    var attempts = 0;
    while (_running && !_disposed) {
      try {
        await _connectOnce();
        attempts = 0;
      } on Object catch (error) {
        if (!_running || _disposed) break;
        attempts += 1;
        final backoff = Duration(seconds: attempts.clamp(1, 8));
        _log('SSE reconnect in ${backoff.inSeconds}s: $error');
        await Future<void>.delayed(backoff);
      }
    }
  }

  Future<void> _connectOnce() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token for realtime stream');
    }

    final client = http.Client();
    _activeClient = client;

    final request = http.Request(
      'GET',
      Uri.parse('${Env.baseUrl}/realtime/stream'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    final response = await client.send(request);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        final refreshed = await TokenRefreshService.refreshToken();
        if (refreshed) {
          throw StateError('Realtime stream token refreshed, reconnecting');
        }
      }
      throw StateError('Realtime stream failed: HTTP ${response.statusCode}');
    }

    var currentEventName = '';
    final dataLines = <String>[];

    await for (final line
        in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!_running || _disposed) {
        break;
      }

      if (line.isEmpty) {
        _dispatchEvent(
          eventName: currentEventName.isEmpty ? 'message' : currentEventName,
          dataLines: dataLines,
        );
        currentEventName = '';
        dataLines.clear();
        continue;
      }

      if (line.startsWith(':')) {
        continue;
      }

      if (line.startsWith('event:')) {
        currentEventName = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    client.close();
    if (identical(_activeClient, client)) {
      _activeClient = null;
    }
  }

  void _dispatchEvent({
    required String eventName,
    required List<String> dataLines,
  }) {
    if (dataLines.isEmpty) {
      return;
    }

    final joined = dataLines.join('\n');
    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = json.decode(joined);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } on Object {
      return;
    }

    final type = payload['type']?.toString().trim();
    if (type == null || type.isEmpty) {
      return;
    }

    _controller.add(
      RealtimeEvent(
        type: type,
        payload: payload,
        rawEventName: eventName,
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[RealtimeEventService] $message');
    }
  }
}
