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

  void start() {
    transportDataServiceMock.start(
      (accumulator) async {
        _commonTimer ??= Timer.periodic(const Duration(milliseconds: 200), (timer) {
          onAnimationTick?.call(_animationData);
        });

        for (final vm in accumulator.values) {
          late int vmIndex;
          final oldVm = _animationData.firstWhereOrNull((vehicleMovement) => vehicleMovement.id == vm.id);

          // добавить новые данные в анимационный массив, если такого участка geojson еще нет
          if (oldVm == null) {
            _animationData.add(vm);
            vmIndex = _animationData.length - 1;
            continue;
          } else {
            vmIndex = _animationData.indexWhere((vehicleMovement) => vehicleMovement.id == oldVm.id);
          }

          // запустить анимации для нужных участков geojson
          // запускать только при существенной разнице координат?
          if (vm.point != oldVm.point) {
            final distance = calculateDistance(vm.point, oldVm.point);
            final timeInMilliseconds = 3000; // (calculateTime(_kSpeed, distance) * 1000).round();

            final countdownTimer = CountdownStream(initialMilliseconds: timeInMilliseconds, tickMilliseconds: 200);

            // TODO попроьовать цикл while
            countdownTimer.stream.listen((millisecondsOstalos) {
              // TODO need help

              final millisecondsProshlo = timeInMilliseconds - millisecondsOstalos;
              final animationPercentage = millisecondsProshlo / timeInMilliseconds;

              // default values
              double latitude = oldVm.point.latitude;
              double longitude = oldVm.point.longitude;

              // animate values
              final deltaLat = (vm.point.latitude - latitude) * animationPercentage;
              final deltaLon = (vm.point.longitude - longitude) * animationPercentage;

              latitude += deltaLat;
              longitude += deltaLon;

              // update values in _animationData
              _animationData[vmIndex].point = LatLng(latitude, longitude);
            });
            countdownTimer.onComplete = () {
              countdownTimer.dispose();
            };
            countdownTimer.startTimer();
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

double calculateDistance(LatLng coord1, LatLng coord2) {
  final double lat1 = coord1.latitude;
  final double lon1 = coord1.longitude;
  final double lat2 = coord2.latitude;
  final double lon2 = coord2.longitude;
  const p = 0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  const radiusOfEarth = 6371;
  return 1000 * radiusOfEarth * 2 * asin(sqrt(a)); // result in meters
}

double calculateTime(double speed, double distance) {
  return distance / speed;
}

/// A countdown timer class that provides a stream of countdown Millisicks.
///
/// This class allows you to start a countdown timer of a specified duration,
/// pause, resume, reset, and dispose the timer, while listening to the countdown
/// updates via a broadcast stream.
///
/// Example usage:
/// ```
/// final countdown = CountdownStream(initialSeconds: 10);
///
/// countdown.stream.listen((seconds) {
///   print('$seconds values remaining');
/// });
///
/// countdown.startTimer();
///
/// // Later on...
/// countdown.pauseTimer();
///
/// // And then...
/// countdown.resumeTimer();
///
/// // Finally, when done...
/// countdown.dispose();
/// ```
class CountdownStream {
  /// Initial countdown value in milliseconds.
  final int initialMilliseconds;

  /// Current countdown value in milliseconds.
  int currentMilliseconds;

  /// Timer object to manage the countdown.
  Timer? _timer;

  /// StreamController to broadcast countdown updates.
  final StreamController<int> _streamController = StreamController<int>.broadcast();

  /// Duration between each tick of the countdown.
  final Duration tickDuration;

  /// Callback functions that can be set to react to different events.
  Function()? onComplete;
  Function()? onResumed;
  Function()? onPaused;
  Function()? onReset;
  Function()? onDispose;

  /// Constructor to initialize the CountdownStream with optional initial values and tick duration.
  CountdownStream({
    this.initialMilliseconds = 10000,
    int tickMilliseconds = 10,
  })  : currentMilliseconds = initialMilliseconds,
        tickDuration = Duration(milliseconds: tickMilliseconds);

  /// Getter to expose the stream of countdown updates.
  Stream<int> get stream => _streamController.stream;

  /// Starts or resumes the countdown timer. Optionally resets the countdown to initial values.
  void startTimer([bool reset = true]) {
    if (_timer != null && _timer!.isActive) return;

    if (reset) currentMilliseconds = initialMilliseconds;
    _timer = Timer.periodic(tickDuration, (Timer timer) {
      if (currentMilliseconds == 0) {
        stopTimer();
        if (onComplete != null) onComplete!(); // Callback when countdown completes.
      } else {
        currentMilliseconds--;
        _streamController.add(currentMilliseconds); // Update listeners with the current value.
      }
    });
  }

  /// Pauses the countdown timer if it is active.
  void pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer?.cancel();
      _timer = null;
      if (onPaused != null) onPaused!(); // Callback when countdown is paused.
    }
  }

  /// Resumes the countdown from the current value if the timer is not active.
  void resumeTimer() {
    if (_timer != null || currentMilliseconds <= 0) return;
    startTimer(false);
    if (onResumed != null) onResumed!(); // Callback when countdown is resumed.
  }

  /// Stops the countdown timer and notifies listeners with the current value.
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _streamController.add(currentMilliseconds);
  }

  /// Resets the countdown timer to the initial values and updates listeners.
  void resetTimer() {
    stopTimer();
    currentMilliseconds = initialMilliseconds;
    _streamController.add(currentMilliseconds);
    if (onReset != null) onReset!(); // Callback when countdown is reset.
  }

  /// Disposes resources used by the countdown timer and stream controller.
  void dispose() {
    _timer?.cancel();
    _streamController.close();
    if (onDispose != null) onDispose!(); // Callback when object is disposed.
  }
}
