import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_transport_example/map/transport/data/transport_animation_service.dart';
import 'package:maplibre_transport_example/map/transport/data/transport_web_socket.dart';

import '../ui/map_screen.dart';
import 'data/transport_data_service.dart';
import 'models/models.dart';

const _kTransportGeoJsonSourceId = "transport_geo_json_source_id";
const _kTransportSymbolLayerId = "transport_symbol_layer_id";

class TransportLayer extends StatefulWidget {
  const TransportLayer({
    required this.mapController,
    super.key,
  });

  final MapLibreMapController mapController;

  @override
  State<TransportLayer> createState() => _TransportLayerState();
}

class _TransportLayerState extends State<TransportLayer> {
  late final TransportWebSocketService _transportWebSocketService;
  // late final TransportDataServiceMock _transportDataServiceMock;
  late final TransportDataService _transportDataService;
  late final TransportAnimationService _transportAnimationService;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final presenter = MapScreenPresenter.of(context);
      _transportWebSocketService = TransportWebSocketService(
        url: "wss://gm-mobile-dev.city-mob.com/api/socket/websocket?vsn=2.0.0",
      );
      // _transportDataServiceMock = TransportDataServiceMock();
      _transportDataService = TransportDataService(
        webSocket: _transportWebSocketService,
      );
      _transportAnimationService = TransportAnimationService(
        transportDataService: _transportDataService,
        onAnimationTick: _updateLayer,
      );
      presenter.bboxSubject$.listen((bbox) {
        _transportAnimationService.setBBox(bbox);
      });
      presenter.zoomSubject$.listen((zoom) {
        _transportAnimationService.setZoom(zoom);
        // print("zoom:  $zoom");
      });
      await _addLayer();

      _transportAnimationService.start();
    });
  }

  Map<String, dynamic> getGeoJsonTransportData(Map<String, VehicleMovement> vehicleMovements) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final vm in vehicleMovements.values) vm.toGeoJsonFeature(),
      ],
    };
  }

  Future<void> _addLayer() async {
    await widget.mapController.addGeoJsonSource(
      _kTransportGeoJsonSourceId,
      <String, dynamic>{
        'type': 'FeatureCollection',
        'features': [],
      },
    );
    await widget.mapController.addSymbolLayer(
      _kTransportGeoJsonSourceId,
      _kTransportSymbolLayerId,
      SymbolLayerProperties(
        iconImage: "assets/raster/bus_point.png",
        iconRotate: ["get", "bearing"],
        iconRotationAlignment: "map", // auto
        iconAnchor: "center", // bottom, center, top
        textField: [Expressions.get, "routeName"],
        textHaloWidth: 2,
        textSize: 12,
        textColor: const Color(0x00000000).toHexStringRGB(),
        textHaloColor: const Color(0xFFFFFFFF).toHexStringRGB(),
        textOffset: [
          Expressions.literal,
          [0, 1.5],
        ],
        // iconSize: fwdStaticMarker.iconSize,
        iconAllowOverlap: true,
      ),
    );
  }

  Future<void> _updateLayer(Map<String, VehicleMovement> vehicleMovements) async {
    await widget.mapController.setGeoJsonSource(
      _kTransportGeoJsonSourceId,
      getGeoJsonTransportData(vehicleMovements),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
