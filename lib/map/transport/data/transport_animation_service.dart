// import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/models.dart';
import 'transport_data_service.dart';

// const _kSpeed = 10.0; // meters per value

class TransportAnimationService {
  final TransportDataServiceMock transportDataServiceMock;

  TransportAnimationService({
    required this.transportDataServiceMock,
    required this.onAnimationTick,
  });

  Timer? _commonTimer;
  final List<VehicleMovement> _animationData = [];
  final Function(List<VehicleMovement>)? onAnimationTick;
  LatLngBounds? bbox;

  void setBBox(LatLngBounds newBbox) {
    bbox = newBbox;
    print("oaoaooaoa");
  }

  void start() {
    transportDataServiceMock.start(
      (accumulator) async {
        _commonTimer ??= Timer.periodic(const Duration(milliseconds: 100), (timer) {
          onAnimationTick?.call(_animationData);
        });
        for (final vm in accumulator.values) {
          late int vmIndex;
          final oldVm = _animationData.firstWhereOrNull((vehicleMovement) => vehicleMovement.id == vm.id);

          if (oldVm == null) {
            _animationData.add(vm);
            vmIndex = _animationData.length - 1;
            continue;
          } else {
            vmIndex = _animationData.indexWhere((vehicleMovement) => vehicleMovement.id == oldVm.id);
          }

          final oldPoint = _normalizeCoordinates(oldVm.point);
          final newPoint = _normalizeCoordinates(vm.point);

          if (bbox != null && !_pointInBBox(newPoint, bbox!) && !_pointInBBox(oldPoint, bbox!)) {
            _animationData.removeAt(vmIndex);
            continue;
          } else {
            if (newPoint != oldPoint && !_arePointsCloseEnough(newPoint, oldPoint)) {
              const int duration = 5000; // время анимации в миллисекундах
              const int steps =
                  50; // количество шагов анимации. Должен высчитываться из врвмени и скорости, но не превышать определенное максимальное значение
              final double diffLat = (newPoint.latitude - oldPoint.latitude) / steps;
              final double diffLng = (newPoint.longitude - oldPoint.longitude) / steps;
              int step = 0;
              Timer.periodic(const Duration(milliseconds: duration ~/ steps), (timer) {
                step++;
                if (step == steps) {
                  timer.cancel();
                }
                double newLat = oldPoint.latitude + step * diffLat;
                double newLng = oldPoint.longitude + step * diffLng;
                _animationData[vmIndex].point = _normalizeCoordinates(LatLng(newLat, newLng));
              });
            }
          }
        }
      },
    );
  }

  void stop() {
    _commonTimer?.cancel();
    _commonTimer = null;
  }
}

bool _pointInBBox(LatLng point, LatLngBounds bbox) {
  if (point.latitude >= bbox.southwest.latitude &&
      point.latitude <= bbox.northeast.latitude &&
      point.longitude >= bbox.southwest.longitude &&
      point.longitude <= bbox.northeast.longitude) {
    return true;
  } else {
    return false;
  }
}

double _calculateDistance(LatLng coord1, LatLng coord2) {
  final double lat1 = coord1.latitude;
  final double lon1 = coord1.longitude;
  final double lat2 = coord2.latitude;
  final double lon2 = coord2.longitude;
  const p = 0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  const radiusOfEarth = 6371;
  return 1000 * radiusOfEarth * 2 * asin(sqrt(a)); // result in meters
}

double _calculateTime(double speed, double distance) {
  return distance / speed;
}

LatLng _normalizeCoordinates(LatLng latLng) {
  if (latLng.latitude > 90 || latLng.latitude < -90) {
    return LatLng(latLng.latitude % 180, latLng.longitude);
  } else {
    return latLng;
  }
}

bool _arePointsCloseEnough(LatLng point1, LatLng point2, [double epsilon = 0.0001]) {
  final latDiff = point1.latitude - point2.latitude;
  final lngDiff = point1.longitude - point2.longitude;

  // Check if the distance between the points is less than epsilon
  return sqrt(latDiff * latDiff + lngDiff * lngDiff) < epsilon;
}
