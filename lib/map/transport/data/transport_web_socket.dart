import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';

class TransportWebSocketService {
  static int heartbeatCounter = 0;

  TransportWebSocketService({required String url}) : _url = url;

  final String _url;

  bool _isInitialized = false;

  bool get isProcessing => _isInitialized;

  late StreamSubscription<dynamic> socketSub;
  Timer? _updateSocketTimer;
  Timer? _heartbeatTimer;

  IOWebSocketChannel? _channel;

  Future<void> _startGetData(void Function(Map<String, dynamic>)? onData) async {
    _channel = IOWebSocketChannel.connect(
      Uri.parse(_url),
      pingInterval: const Duration(minutes: 1),
      connectTimeout: const Duration(seconds: 30),
    );
    _channel?.sink.add(
      jsonEncode(
        [
          '3',
          '3',
          'vehicles',
          'phx_join',
          <dynamic, dynamic>{},
        ],
      ),
    );

    socketSub = _channel!.stream.listen(
      (dynamic raw) {
        final decodedData = jsonDecode(raw.toString()) as List<dynamic>;
        for (final rawData in decodedData) {
          if (rawData.runtimeType != String && rawData.runtimeType != Null) {
            onData?.call(rawData as Map<String, dynamic>);
          }
        }
      },
      onError: (Object o) => debugPrint('Socket error: $o'),
      cancelOnError: false,
    );
  }

  Future<void> start(void Function(Map<String, dynamic>)? onData) async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    await _startGetData(onData);

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _heartbeat();
    });

    _updateSocketTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      debugPrint('Socket ${await _channel?.sink.done}');

      if (_channel?.closeCode != null && isProcessing) {
        debugPrint('Test Data Socket is closed with code: ${_channel?.closeCode}');
        unawaited(_startGetData(onData));
      }
    });
  }

  Future<void> stop() async {
    if (!_isInitialized) {
      return;
    }
    _isInitialized = false;

    if (_updateSocketTimer?.isActive ?? false) {
      _updateSocketTimer?.cancel();
    }

    if (_heartbeatTimer?.isActive ?? false) {
      _heartbeatTimer?.cancel();
    }

    await socketSub.cancel();
    await _channel?.sink.close();
  }

  void _heartbeat() {
    debugPrint('Test Data Heartbeat $heartbeatCounter');

    _channel?.sink.add(
      jsonEncode(
        [
          "null",
          "${heartbeatCounter++}",
          "phoenix",
          "hearbeat",
          <dynamic, dynamic>{},
        ],
      ),
    );
  }
}
