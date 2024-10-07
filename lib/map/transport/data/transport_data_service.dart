import '../models/models.dart';
import 'transport_web_socket.dart';

class TransportDataService {
  TransportDataService({required TransportWebSocketService webSocket}) : _webSocket = webSocket;

  Map<String, VehicleMovement> get rawTransportData => _accumulator;

  final TransportWebSocketService _webSocket;
  final Map<String, VehicleMovement> _accumulator = {};
  Future<void> Function(Map<String, VehicleMovement> accumulator)? _onNewData;

  Future<void> start(
    Future<void> Function(Map<String, VehicleMovement> accumulator)? onNewData,
  ) async {
    if (_webSocket.isProcessing) {
      return;
    }
    _onNewData = onNewData;
    await _webSocket.start(_responseMapper);
  }

  Future<void> removeVehicle(String key) async {
    _accumulator.remove(key);
  }

  Future<void> dispose() async {
    await _webSocket.stop();
    _accumulator.clear();
  }

  Future<void> _responseMapper(Map<String, dynamic> raw) async {
    final vehicles = <VehicleMovement>[];

    // if (raw.containsKey('response')) - при присоединении к сокету
    // else if (raw.containsKey('id')) - при получении данныж от сокета
    if (raw.containsKey('response')) {
      if (raw['response']['vehicles'] != null) {
        final rawVehicles = raw['response']['vehicles'] as List<dynamic>;
        for (var i = 0; i < rawVehicles.length; i++) {
          final vehicle = VehicleMovementFromJson.fromJson(rawVehicles[i] as Map<String, dynamic>);
          if (vehicle != null) {
            vehicles.add(vehicle);
          }
        }
      }
    } else if (raw.containsKey('id')) {
      final vehicle = VehicleMovementFromJson.fromJson(raw);
      if (vehicle != null) {
        vehicles.add(vehicle);
      }
    }

    for (final vehicleMovement in vehicles) {
      final key = vehicleMovement.id;
      if (!_accumulator.containsKey(key)) {
        _accumulator.putIfAbsent(key, () => vehicleMovement);
      } else if (_accumulator[key]?.timestamp.isBefore(vehicleMovement.timestamp) == true) {
        _accumulator.update(key, (value) => vehicleMovement);
      }
    }
    _onNewData?.call(_accumulator);
  }
}
