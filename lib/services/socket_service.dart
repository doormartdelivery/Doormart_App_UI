import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants.dart';

class SocketService {
  io.Socket? _socket;

  bool get connected => _socket?.connected ?? false;

  void connect({
    String? token,
    void Function(dynamic data)? onOrderCreated,
    void Function(dynamic data)? onOrderAccepted,
    void Function(dynamic data)? onOrderPickedUp,
    void Function(dynamic data)? onOrderDelivered,
  }) {
    if (_socket != null) {
      return;
    }

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {});
    if (onOrderCreated != null) {
      _socket?.on('order_created', onOrderCreated);
      _socket?.on('new_order_request', onOrderCreated);
    }
    if (onOrderAccepted != null) {
      _socket?.on('order_assigned', onOrderAccepted);
      _socket?.on('order:accepted', onOrderAccepted);
    }
    if (onOrderPickedUp != null) {
      _socket?.on('order_picked_up', onOrderPickedUp);
      _socket?.on('order:pickedup', onOrderPickedUp);
    }
    if (onOrderDelivered != null) {
      _socket?.on('order_delivered', onOrderDelivered);
      _socket?.on('order:delivered', onOrderDelivered);
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
