import 'dart:async';

class AuthSessionNotifier {
  AuthSessionNotifier._();

  static final AuthSessionNotifier instance = AuthSessionNotifier._();

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
