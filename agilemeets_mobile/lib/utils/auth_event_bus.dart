import 'dart:async';

enum AuthenticationEvent {
  unauthorized,
  tokenRefreshed,
  loggedOut,
}

class AuthEventBus {
  final _controller = StreamController<AuthenticationEvent>.broadcast();

  Stream<AuthenticationEvent> get stream => _controller.stream;

  void add(AuthenticationEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final authEventBus = AuthEventBus();
