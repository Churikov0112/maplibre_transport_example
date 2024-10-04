// import 'package:flutter/foundation.dart';

// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/models.dart';
import 'transport_data_service.dart';

const _kMinZoom = 12.0;

class TransportAnimationService {
  final TransportDataService transportDataService;

  TransportAnimationService({
    required this.transportDataService,
    required this.onAnimationTick,
  });

  Timer? _commonTimer;
  Map<String, VehicleMovement> _animationData = {};
  Function(Map<String, VehicleMovement>)? onAnimationTick;
  LatLngBounds? bbox;
  double? zoom;

  void setBBox(LatLngBounds newBbox) {
    bbox = newBbox;
  }

  void setZoom(double newZoom) {
    zoom = newZoom;
  }

  _startCommonTimer() {
    _commonTimer ??= Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (zoom == null || zoom! < _kMinZoom) {
        onAnimationTick?.call({});
      } else {
        onAnimationTick?.call(_animationData);
      }
    });
  }

  void start() {
    _startCommonTimer();
    transportDataService.start(
      (accumulator) async {
        for (final vm in accumulator.values) {
          final oldVm = _animationData[vm.id];
          final oldPoint = oldVm?.point; // _normalizeCoordinates(oldVm?.point);
          final newPoint = vm.point; // _normalizeCoordinates(vm.point);
          if (oldVm == null) {
            if (_pointInBBox(newPoint, bbox)) {
              _animationData[vm.id] = vm;
              continue;
            }
          } else {
            if (_pointInBBox(oldPoint, bbox) || _pointInBBox(newPoint, bbox)) {
              if (oldPoint != null) {
                if (newPoint != oldPoint) {
                  const double speed = 10; // метров в секунду
                  final distance = _calculateDistance(oldPoint, newPoint); // метров
                  final time = 1000 * _calculateTime(speed, distance); // милисекунд
                  final int steps = time ~/ 20; // количество шагов анимации
                  int step = 0;

                  Timer.periodic(Duration(milliseconds: time ~/ steps), (timer) {
                    step++;
                    if (step == steps) {
                      _animationData[vm.id]?.point = newPoint;
                      timer.cancel();
                    }
                    double newLat = oldPoint.latitude + (step / steps) * (newPoint.latitude - oldPoint.latitude);
                    double newLng = oldPoint.longitude + (step / steps) * (newPoint.longitude - oldPoint.longitude);
                    _animationData[vm.id]?.point = LatLng(newLat, newLng);
                  });
                }
              }
            } else {
              _animationData.remove(vm.id);
              continue;
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

bool _pointInBBox(LatLng? point, LatLngBounds? bbox) {
  if (bbox == null || point == null) {
    return false;
  }
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
  return 1000 * radiusOfEarth * 2 * asin(sqrt(a));
}

double _calculateTime(double speed, double distance) {
  return distance / speed;
}

// LatLng? _normalizeCoordinates(LatLng? latLng) {
//   if (latLng == null) {
//     return null;
//   }
//   if (latLng.latitude > 90 || latLng.latitude < -90) {
//     return LatLng(latLng.latitude % 180, latLng.longitude);
//   } else {
//     return latLng;
//   }
// }

// bool _arePointsCloseEnough(LatLng point1, LatLng point2, [double epsilon = 0.0001]) {
//   final latDiff = point1.latitude - point2.latitude;
//   final lngDiff = point1.longitude - point2.longitude;
//   return sqrt(latDiff * latDiff + lngDiff * lngDiff) < epsilon;
// }