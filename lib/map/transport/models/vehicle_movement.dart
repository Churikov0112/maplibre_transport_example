part of 'models.dart';

enum Direction { forward, back }

extension DirectionJson on Direction {
  static Direction fromJson(int type) {
    switch (type) {
      case 0:
        return Direction.forward;
      case 1:
        return Direction.back;
      default:
        return Direction.forward;
    }
  }
}

class VehicleMovementStep extends Equatable {
  const VehicleMovementStep({
    required this.index,
    required this.bearing,
    required this.coordinate,
    required this.duration,
  });

  final int index;
  final LatLng coordinate;
  final Duration duration;
  final double? bearing;

  @override
  List<Object?> get props => [
        index,
        bearing,
        coordinate,
        duration,
      ];
}

class VehicleMovement {
  final String id;
  LatLng point;
  double bearing;
  DateTime timestamp;
  bool isPaymentAvaliable;
  Direction direction;
  final double normDist;
  final MobilityType type;
  final int routeId;
  final String routeName;

  VehicleMovement({
    required this.id,
    required this.bearing,
    required this.point,
    required this.timestamp,
    required this.direction,
    required this.normDist,
    required this.type,
    required this.routeId,
    required this.routeName,
    required this.isPaymentAvaliable,
  });
}

extension VehicleMovementFromJson on VehicleMovement {
  static VehicleMovement? fromJson(Map<String, dynamic> json) {
    final id = _cast<String>(json['id']);
    final type = _MobitityTypeMappers.fromString(json['vehicle_type'] as String?);
    final rawTimestamp = _castToInt(json['timestamp']);
    final routeId = _castToInt(json['route_id']);
    final routeName = json['route_name'] != null ? '${json['route_name']}' : null;

    if (id == null || type == null || rawTimestamp == null || routeId == null || routeName == null) {
      return null;
    }

    return VehicleMovement(
      // важно всегда
      point: LatLng(json['coords'][1], json['coords'][0]),
      direction: DirectionJson.fromJson(json['direction'] as int),
      normDist: (json['normalized_dist'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(rawTimestamp * 1000, isUtc: true).toLocal(),
      // важно в самом начале
      routeId: routeId,
      routeName: routeName,
      type: type,
      id: id,
      bearing: json['bearing'] is num ? (json['bearing'] as num).toDouble() : 0.0,
      isPaymentAvaliable: json['is_payment_avaliable'] as bool,
    );
  }
}

extension VehicleMovementToGeoJson on VehicleMovement {
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      "type": "Feature",
      "id": id,
      "properties": {
        "bearing": bearing,
      },
      "geometry": {
        "type": "Point",
        "coordinates": [point.longitude, point.latitude],
      },
    };
  }
}

T? _cast<T>(dynamic x) => x is T ? x : null;

int? _castToInt(dynamic x) {
  final asInt = _cast<int>(x);
  final asString = _cast<String>(x);
  return asInt ?? (asString != null ? int.tryParse(asString) : null);
}
