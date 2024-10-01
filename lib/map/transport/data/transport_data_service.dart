// import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/models.dart';

class TransportDataServiceMock {
  Map<String, VehicleMovement> get rawTransportData => _accumulator;

  final Map<String, VehicleMovement> _accumulator = {};
  // Future<void> Function(String key)? _updateVehicle;

  Future<void> start(
    Future<void> Function(Map<String, VehicleMovement> accumulator)? onNewData,
    // Future<void> Function(String key)? updateVehicle,
  ) async {
    // _updateVehicle = updateVehicle;
    final ran = Random();

    Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final list = List.generate(
          1000,
          (index) => VehicleMovement(
            bearing: 0,
            point: LatLng(59.9386 + (ran.nextDouble() / 100), 30.3141 + (ran.nextDouble() / 100)),
            timestamp: DateTime.now(),
            direction: Direction.forward,
            normDist: 1000,
            id: 'id $index',
            type: MobilityType.bus,
            routeId: 0,
            routeName: 'routeName',
            isPaymentAvaliable: true,
          ),
        );

        for (final vehicleMovement in list) {
          final key = vehicleMovement.id;
          if (!_accumulator.containsKey(key)) {
            _accumulator.putIfAbsent(key, () => vehicleMovement);
            // await _updateVehicle?.call(key);
          } else if (_accumulator[key]?.timestamp.isBefore(vehicleMovement.timestamp) == true) {
            _accumulator.update(key, (value) => vehicleMovement);
            // await _updateVehicle?.call(key);
          }
        }
        onNewData?.call(_accumulator);
      },
    );
  }

  Future<void> dispose() async {
    _accumulator.clear();
  }

  Future<void> removeVehicle(String key) async {
    _accumulator.remove(key);
  }
}
